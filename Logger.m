classdef Logger < handle % By extending "handle" we get normal class behavior
    %LOGGER Simple logging class

    properties
        cb
        log_data
    end

    properties (SetAccess = protected, GetAccess = protected)
        echo % If true, echo log events to CLI as they come in
    end

    methods
        function obj = Logger()
            obj.Clear();
        end

        function echoToCli(obj, enabled)
            % ECHO Enable or disable echoing log events to command line.
            obj.echo = logical(enabled);
        end

        function data = GetLog(obj)
            % GETLOG Return the log as a single string.
            data = obj.log_data;
        end

        function Clear(obj)
            % CLEAR Clear the contents of the log.

            obj.log_data = "";
            if isa(obj.cb, 'function_handle')
                % Sending an empty string to the callback indicates that
                % the log data should be replaced entirely rather than
                % simply appending the new message.
                obj.cb("", obj.log_data);
            end
        end

        function Info(obj, msg)
            m = strcat(datestr(now), " :: INFO  :: ", msg);
            if obj.echo
                fprintf(m + "\n");
            end

            obj.append(m);
        end

        function Warn(obj, msg)
            m = strcat(datestr(now), " :: WARN  :: ", msg);
            if obj.echo
                fprintf(m + "\n");
            end

            obj.append(m);
        end

        function Error(obj, msg)
            m = strcat(datestr(now), " :: ERROR :: ", msg);
            if obj.echo
                fprintf(m + "\n");
            end

            obj.append(m);
        end

        function Debug(obj, msg)
            m = strcat(datestr(now), " :: DEBUG :: ", msg);
            if obj.echo
                fprintf(m + "\n");
            end

            obj.append(m);
        end

        function SetCallback(obj, cb)
            obj.cb = cb;
        end

        function ClearCallback(obj)
            delete(obj.cb);
        end
    end

    methods (Access = private)
        function append(obj, msg)
            % MATLAB is truly insane. strcat() strips newlines... but you
            % can get around that by putting the newline inside a cell?!?
            % Also, it works fine without the cell if you're just dumping
            % text to the console, but not when you're going to show the
            % result in a textarea.
            % https://www.mathworks.com/matlabcentral/answers/93333-why-does-the-strcat-command-remove-the-trailing-spaces-while-performing-a-concatenation-in-matlab-7
            obj.log_data = strcat(obj.log_data, msg, {newline});

            if isa(obj.cb, 'function_handle')
                obj.cb(msg, obj.log_data);
            end
        end
    end
end

