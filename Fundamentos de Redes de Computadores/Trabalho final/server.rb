#Author: Nicolás Caorsi
require 'socket'
require 'zlib'
require 'logger'
require_relative 'packet'

logger = Logger.new(STDOUT)

u1 = UDPSocket.new
u1.bind("127.0.0.1", 4914)

received_packets = Array.new
while true
  msg, addr = u1.recvfrom(65507)

  received_crc_32 = msg[msg.length-10, msg.length-1].to_i # ToDo Tratar para nao inteiros
  logger.info("Raw packet received: #{msg}")
  received_packet = Packet.new( :type => msg[msg.length - 64].to_i,
				:ack_number => msg[msg.length - 63],
				:data_size => msg[msg.length - 62, msg.length - 60].to_i,
				:data => msg[msg.length - 60, msg.length - 14]
  )
  logger.info("Packet received #{received_packet.to_s}")
  received_successfully = received_packet.crc_32 == received_crc_32

  if(received_successfully)
    if(received_packet.type == 4)
      u1.send Packet.new(:type => received_successfully ? 1 : 0).data_frame, 0, addr[3], addr[1]
      logger.info('End of file')
      break
    elsif(received_packets.empty? || received_packet.ack_number != received_packets.last.ack_number)
      logger.info('Packet received successfully...')
      received_packet.data = msg[msg.length - received_packet.data_size - 10, msg.length - 14]
      received_packet.data = received_packet.data[0, received_packet.data_size]
      received_packets << received_packet
      logger.info("#{received_packet.to_s}")
    else
      logger.info('Packet already received, ignoring...')
    end
  else
    logger.info("CRC32 does not match expected value was #{received_packet.crc_32} but received was #{received_crc_32}!")
    logger.info("#{received_packet.to_s}")
  end

  u1.send Packet.new(:type => received_successfully ? 1 : 0).data_frame, 0, addr[3], addr[1]

end

  # Save the packets to a file.
  fileName = received_packets.delete_at(0).data
  fileStr = ""
  received_packets.each{
    |a|
    fileStr << a.data
  }
  # Concatenate name of file with current date to avoid conflicts
  aFile = File.new("Received file at #{Time.new.inspect} #{fileName}", "w")
  aFile.write(fileStr)
  aFile.close
