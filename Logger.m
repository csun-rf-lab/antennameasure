classdef Logger < handle % By extending "handle" we get normal class behavior
    %LOGGER Simple logging class

    properties
        cb
        log_data
    end

    methods
        function obj = Logger()
            obj.Clear();
        end

        function data = GetLog(obj)
            data = obj.log_data;
        end

        function Clear(obj)
            obj.log_data = "";
            if isa(obj.cb, 'function_handle')
                % Sending an empty string to the callback indicates that
                % the log data should be replaced entirely rather than
                % simply appending the new message.
                obj.cb("", obj.log_data);
            end
        end

        function Info(obj, msg)
            obj.append(strcat(datestr(now), " :: INFO  :: ", msg));
        end

        function Error(obj, msg)
            obj.append(strcat(datestr(now), " :: ERROR :: ", msg));
        end

        function Debug(obj, msg)
            obj.append(strcat(datestr(now), " :: DEBUG :: ", msg));
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

