require 'zlib'

class Packet  
  attr_accessor :type, :sequence_number, :ack_number, :data_size, :data, :crc_32

  def initialize(options = {})  
    @type = options[:type]
    @sequence_number = options[:sequence_number]
    @ack_number = options[:ack_number]
    @data_size = options[:data_size]
    @data = options[:data]
    #@size = options[:size] || 0  
  end
  
  def crc_32
    calculate_crc_32
    @crc_32
  end

  def calculate_crc_32
    @crc_32 = Zlib::crc32(@type.to_s << @ack_number.to_s << (@data_size != nil ? @data_size.to_s.rjust(2): "") << (@data ? @data.to_s.rjust(50) : ''))
  end

  def data_frame
    calculate_crc_32
    @type.to_s << @ack_number.to_s << (@data_size != nil ? @data_size.to_s.rjust(2): "") << (@data ? @data.to_s.rjust(50) : '') << @crc_32.to_s.rjust(10)
  end

  def to_s
    calculate_crc_32
    "{type:#{@type}, sequence_number:#{@sequence_number}, ack_number:#{@ack_number}, data_size:#{@data_size != nil ? @data_size.to_s.rjust(2): ''}, data:#{(@data ? @data.to_s.rjust(50) : '')}, crc_32:#{@crc_32}}"
  end
end
