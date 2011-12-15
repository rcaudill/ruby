require 'rubygems'
require 'serialport'
require 'active_record'

ActiveRecord::Base.establish_connection(
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "",
    :password => "",
    :database => "temperaturemonitor_development"   
)

class TemperatureSensor < ActiveRecord::Base
end

sp = SerialPort.new "/dev/ttyUSB0", 9600

=begin
  Example Arudio Output
  ROM = 10 F6 BD 25 2 8 0 50
  Chip = DS18S20
  Data = 1 1D 0 4B 46 FF FF 3 10 21  CRC=21
  Temperature = 14.56 Celsius, 58.21 Fahrenheit
=end


bufferline1=""
bufferline2=""
bufferline3=""
bufferline4=""

h = Hash.new
t = Time.now

begin
  while (line = sp.gets) do
    # 4 lines of output for each sensor
    bufferline1=bufferline2
    bufferline2=bufferline3
    bufferline3=bufferline4
    bufferline4=line.strip
    
    if (bufferline1.start_with?("ROM") and bufferline4.include?("Temperature"))
      h[bufferline1.split("=")[1].strip] = bufferline4.split(",")[1].strip.split(" ")[0]
      
      if (t-Time.now<-60)
        t = Time.now
        h.each do |key,value|
          puts "#{key}, #{value}"
          TemperatureSensor.create(:address => key, :temperature => value, :time => Time.now)
        end
        puts "-"    
      end
    end
  end
rescue Exception => e
  puts e
  puts "Caught ctrl-c."
end
sp.close  
puts "Serial port closed. Exiting..."
