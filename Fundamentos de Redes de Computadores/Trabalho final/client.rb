#Author: Nicolás Caorsi

require 'socket'
require 'zlib'
require 'timeout'
require 'logger'
require_relative 'packet'

logger = Logger.new(STDOUT)

def insert_error(str)
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  new_string = str
#Enable this to insert random errors
=begin
  if rand(100) < 50
    new_string[rand(new_string.length)] = chars[rand(chars.length)]
  end
=end
  new_string
end

server_address = ARGV[0]
server_port = '2000'
file_path = ARGV[1]
timeout = 10

packets = Array.new

# File Name
packets << Packet.new(:ack_number => 1, :type => 3, :data_size => File.basename(file_path).length+1, :data => File.basename(file_path))
IO.readlines(file_path, 50).each_with_index do |line, i|
  packets << Packet.new(:ack_number => i.modulo(2), :type => 2, :data_size => line.length, :data => line)
end
#Transmision End
packets << Packet.new(:ack_number => packets.length % 2, :type => 4, :data_size => 0, :data => "".rjust(50))

packets.each{
  |packet|
  socket = UDPSocket.new
  begin
    received_packet = nil
    begin Timeout::timeout(timeout){
      logger.info('Trying to send the packet...')
      logger.info("Sending packet: #{packet.to_s}")

      socket.send insert_error(packet.data_frame), 0, "127.0.0.1", 4914
      logger.info('Packet sent successfully...')

      # Verify server response crc32
      logger.info('Waiting for server response...')
      received_packet_raw = socket.recv(11)
      logger.info('Response received successfully...')
      received_packet = Packet.new(:type => received_packet_raw[0].to_i)
      logger.info('Checking response CRC32...')
      if(received_packet.crc_32 != received_packet_raw[1, received_packet_raw.length-1].to_i) # (crcEsperado != crcRecebido) While arrive fails...
        received_packet = Packet.new(:type => 0)
        logger.info("CRC32 does not match expected value was #{received_packet.crc_32} but received was #{received_packet_raw[1, received_packet_raw.length].to_i}!")
        puts "NACK received... #{received_packet.to_s}"

        sleep 5
      else
        logger.info('CRC32 matched')
      end
    }
    rescue Timeout::Error
      p 'Timeout occurred, resending packet...'
      sleep 5
    end
    if(received_packet.type != 1)
      puts "NACK received... #{received_packet.type}"
    end
#    sleep 5
  end while(received_packet.type != 1) # While network delivery fails...
}

