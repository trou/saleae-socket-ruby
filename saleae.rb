#!/usr/bin/env ruby
require "socket"
require "pp"

class CommandError < StandardError
end

class Saleae
    attr_accessor :s
    
    # All commands that take 1 parameters
    Commands_one_param = [
        :set_num_samples,
        :set_performance,
        :set_sample_rate,
        :set_capture_pretrigger_buffer_size,
        :capture_to_file,
        :save_to_file,
        :load_from_file,
        :select_active_device,
        ]

    Commands_one_param.each do |c|
            define_method(c) do |val|
                puts "c"
                return send_command(c.upcase, [val])
        end
    end

    # Commands returning an int
    Commands_get_int = [
        :get_performance,
        :get_capture_pretrigger_buffer_size
    ]
    Commands_get_int.each do |c|
            define_method(c) do 
                puts "c"
                return send_cmd_get_int(c.upcase)
        end
    end

    # Commands without param
    Commands_no_param = [
        :capture,
        :get_inputs, # Disabled ?
        :reset_active_channels
    ]
    Commands_no_param.each do |c|
            define_method(c) do 
                puts "c"
                return send_command(c.upcase)
        end
    end

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
            pp resp
            resp_lines += resp.split("\n")
        end while resp_lines.index("ACK") == nil and resp_lines.index("NAK") == nil
        if resp_lines.index("NAK") then
            raise CommandError
        else
            resp_lines.delete("ACK")
        end
        pp resp_lines
        return resp_lines
    end

    # Send a command, return the first line
    # parsed as an array of ints
    def send_cmd_get_ints(cmd_str, args=[])
        res = send_command(cmd_str, args)
        return res.first.split(',').map {|r| r.to_i }        
    end
 
    # Send a command, return the first line
    # parsed as an int
    def send_cmd_get_int(cmd_str, args=[])
        res = send_command(cmd_str, args)
        return res[0].to_i
    end

    def set_trigger(trigs)
    end

    def get_all_sample_rates()
        return send_cmd_get_ints("GET_ALL_SAMPLE_RATES")
    end

    def get_connected_devices()
        return send_command("GET_CONNECTED_DEVICES")
    end

    def get_analyzers()
        return send_command("GET_ANALYZERS")
    end

    def get_active_channels()
        res = send_command("GET_ACTIVE_CHANNELS").pop.split(',')
        digital = []
        analog = []
        a_idx = res.index("analog_channels")
        d_idx = res.index("digital_channels")
        if d_idx < a_idx then
            digital = res[d_idx+1..a_idx-1]
            analog = res[a_idx+1..-1]
        else
            analog = res[a_idx+1..d_idx-1]
            digital = res[d_idx+1..-1]
        end
        analog.map!{|c| c.to_i(10)}
        digital.map!{|c| c.to_i(10)}
        return { :digital => digital, :analog => analog}
    end

    def set_active_channels(digital=[], analog=[])
        send_command("SET_ACTIVE_CHANNELS", ["digital_channels"]+digital+["analog_channels"]+analog)
    end

end
