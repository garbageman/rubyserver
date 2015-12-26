require 'socket'
@socket = nil

# Set up server socket then read user input
def main
  # Process the args of the client
  if ARGV.length > 0
    # Convert the argument to an integer to be used as a port number
    port = ARGV[0].to_i
    if port < 1024 || port > 49151
      puts "Illegal port #{ARGV[0].to_i}: Choose one in range 1024-49151"
      exit
    end
  else
    # If no port was specified then the client has nothing to connect to
    puts "No port specified so there is nothing to connect to"
    exit
  end
  start_session port
end

# Create a session and read user input and send it to the server
def start_session port
  puts "Creating client on port #{port}"
  # Set up the socket connection
  @socket = TCPSocket.new('localhost', port)
  $stdout.sync = true

  loop do
    print ">"
    # The only way the client exits is if the user inputs :exit
    input = STDIN.gets
    # Sanitize input
    input.chomp!

    if input == ":exit" then
      # Clean up then exit
      @socket.close
      exit 0
    end

    # If the input isn't exit, then send the message to the appropriate port
    send_message @socket, input
    puts get_message @socket
  end
end

def recv_header socket
  # Receive the header of the message, it will contain the length of
  # the message
  hdr = socket.recv 6
	hdr_bytes = hdr.bytes.to_a
  # If the hdr is empty we have recieved no data so the client has disconnected
  if hdr == ""
    puts "Server disconnected"
    return -1
  # If the hdr length is not 6 then we have read too little and the message isnt complete
  elsif hdr.length != 6
    puts "Stub packet read"
    return -1
  # Check that our parity bytes are correct
  elsif(hdr_bytes[0] != 0x04 || hdr_bytes[1] != 0x50)
    puts "Corrupted packet read"
    return -1
  end
  # Combine the last 4 bytes and convert them to an integer and that will be the length
  # of the message
  hdr_bytes[2...6].join.to_i
end

def recv_body socket, length
  socket.recv length
end

def send_message socket, message
  # Could potentially encode message instead of sending raw string bytes
  if(message.length>=65536)
    puts "Message too long"
    return
  end

  # Do bit shifting to encode the length of the message
  strlen = []
  strlen[0] = (message.length>>24)&0xFF
  strlen[1] = (message.length>>16)&0xFF
  strlen[2] = (message.length>>8)&0xFF
  strlen[3] = (message.length)&0xFF

  # Add the parity bytes to the beginning of the message and send it
  socket.write 0x4.chr+0x50.chr+strlen.pack("CCCC")+message

end

def get_message socket
  # Could decode message instead of just returning the gets
  len = recv_header socket
  if len == -1
    return ""
  end

  recv_body socket, len
end

main
