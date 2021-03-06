-module(sensor_hub).
-export([init/1, start_link/0]).
-behavior(gen_server).
	
% Starts the sensor hub under a supervisor module
start_link() ->
     gen_server:start_link(?MODULE, [], []).	

init([]) ->
	% Start sender process
	link(sensor_hub_sender:start()),
	% Grab all sensors
	Sensors = config_accesser:get_field(sensors),
	% Create a sensor monitor for each sensor
	Pid = spawn_link(fun () -> loop() end),
	spawn_link(sensor_monitor, start, [Sensors, Pid]),
	{ok, sensor_hubState}.


% Receive messages from the sensor monitors
loop() ->
	receive
		{SensorName, Value} ->
			sensor_hub_sender:send_message(
			sensor_json_formatter:sensor_to_json(Value, SensorName)
			),
			loop();
		dispatch -> sensor_hub_sender:send_dispatch(),
			loop()
	end.
