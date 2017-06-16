#!/usr/bin/env ruby

ENV_FILE = "/etc/postfix/mail-receiver-environment.json"

require_relative 'lib/fast_rejection'

if __FILE__ == $0
	receiver = FastRejection.new(ENV_FILE)
	receiver.process
end
