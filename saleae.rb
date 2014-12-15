#!/usr/bin/env ruby
require "socket"
require "pp"

class Saleae
    attr_accessor :s
    
    def initialize(host="localhost", port=10429)
        @s = TCPSocket.new host, port
    end

    def send_command(cmd_str, args=[])
        cmd = ([cmd_str]+args).join(', ')+"\x00"
        puts cmd
        @s.send(cmd, 0)
        resp_lines = []
        begin
            resp = @s.recv(1024)
            resp_lines += resp.split("\n")
        end while resp_lines.index("ACK") == nil and resp_lines.index("NAK") == nil
        pp resp_lines
        return resp_lines
    end

    def set_trigger(trigs)
    end

    def set_num_samples(trigs)
    end
end
