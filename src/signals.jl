type Signal
	name::ASCIIString
	occured::Bool
	wait_list::Set{Process}
	queue_list::Vector{Process}
	function Signal(name::ASCIIString)
		signal = new()
		signal.name = name
		signal.occured = false
		signal.wait_list = Set{Process}()
		signal.queue_list = Process[]
		return signal
	end
end

function show(io::IO, signal::Signal)
	print(io, signal.name)
end

function wait(process::Process, signals::Set{Signal})
	for signal in signals
		add!(signal.wait_list, process)
	end
	cancel(process)
	produce(true)
	occured_signals = Set{Signal}()
	for signal in signals
		if signal.occured
			add!(occured_signals, signal)
		end
		delete!(signal.wait_list, process)
		if isempty(signal.wait_list) 
			signal.occured = false
		end
	end
	return occured_signals
end

function wait(process::Process, signal::Signal)
	signals = Set{Signal}()
	add!(signals, signal)
	return wait(process, signals)
end

function queue(process::Process, signals::Set{Signal})
	for signal in signals
		push!(signal.queue_list, process)
	end
	cancel(process)
	produce(true)
	occured_signals = Set{Signal}()
	for signal in signals
		if signal.occured
			add!(occured_signals, signal)
		end
		delete!(signal.queue_list, findin(signal.queue_list, [process])[1])
		if isempty(signal.wait_list)
			signal.occured = false
		end
	end
	return occured_signals
end

function queue(process::Process, signal::Signal)
	signals = Set{Signal}()
	add!(signals, signal)
	return queue(process, signals)
end

function fire(signal::Signal)
	signal.occured = true
	for process in signal.wait_list
		post(process.simulation, process, now(process), true)
	end
	if ! isempty(signal.queue_list)
		process = signal.queue_list[1]
		post(process.simulation, process, now(process), true)
	end
end