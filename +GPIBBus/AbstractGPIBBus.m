classdef AbstractGPIBBus< handle
    %ABSTRACTCOMMBUS Base class

    properties (SetAccess = protected, GetAccess = protected)
        connected = false % bool: connected to Prologix controller?
        log  % Logger object
        onConnectStateChangeCb
    end

    methods (Abstract)
        connect(obj)
        % Connect to the bus

        disconnect(obj)
        % Disconnect from the bus

        send(obj, recipientAddr, msg)
        % Send a message on the bus

        recv(obj, msg, len)
        % Receive a message from the bus

        fread(obj)
        % Read data from the bus (used in specific scenarios)
    end

    methods
        function conn = isConnected(obj)
            conn = obj.connected;
        end

        function setOnConnectStateChangeCallback(obj, cb)
            obj.onConnectStateChangeCb = cb;
        end

        function clearOnConnectStateChangeCallback(obj)
            clear obj.onConnectStateChangeCb;
        end
    end

    methods (Access = protected)
        function setConnectedState(obj, state)
            obj.connected = state;
            if isa(obj.onConnectStateChangeCb, 'function_handle')
                obj.onConnectStateChangeCb(obj.connected);
            end
        end
    end
end