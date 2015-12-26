require 'socket'

# Create a simple server that echoes what it receives
def main
  # Check that there was an argument supplied to the application
  if ARGV.length > 0
    # Convert the argument to an integer to be used as a port number
    port = ARGV[0].to_i
    if port < 1024 || port > 49151
      puts "illegal port #{ARGV[0].to_i}: Choose one in range 1024-49151"
      exit
    end
  else
    # If no port was specified, create a random port number
    port = Random.new.rand(48128) + 1024
  end
  serve port
end

# Given a port number, create a server on that port and create sessions
# based on incoming requests
def serve port
  # Create a server on the port requested
  puts "Creating server on port: #{port}"
  server  = TCPServer.new port

  # Continuously create new sessions while listening on the port
  loop do
    client = server.accept
    create_session client
  end
end

# Creates a session given the socket
def create_session socket
  puts "Creating new client"
  # Delegate session handling to a thread
  Thread.new do
    # Wait for the socket to get a message
    done = false
    while !done do
      #puts "Waiting for message"
      message = get_message socket
      puts "Got: #{message}"
      # Check that the message isn't empty
      if message == ""
        done = true
      end

      send_message socket, message
    end

    puts "Closing socket"
    # Clean up
    socket.close
  end
end

def recv_header socket
  # Receive the header of the message, it will contain the length of
  # the message
  #puts "Received header"
  hdr = socket.recv 6
	hdr_bytes = hdr.bytes.to_a
  # If the hdr is empty we have recieved no data so the client has disconnected
  if hdr == ""
    puts "client disconnected"
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
  #puts "received body"
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
