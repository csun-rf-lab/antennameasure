classdef MI4190
    %MI4190 Class for controlling MI-4190 motion controller.
    %   This class must be provided a serialport object in the constructor,
    %   and can be used to control any number of axes on the controller.
    
    % TODO: Look at using a mutex to lock the serial port between
    % write/read.
    
    % TODO: Should prologix gpib device be initialized here or before
    % serial port is passed to us?
    
    properties
        Ser   % serialport
        state % State
    end
    
    methods
        function obj = MI4190(sp)
            %MI4190 Construct an instance of this class
            %   You must provide a serialport object.
            obj.Ser = sp;
        end
        
        function obj = moveAxisToPos(obj, axis, position)
            %moveAxisToPos Move a specific axis to a specific position.
            %   Axis is numerical, and position is... probably in degrees.
            % TODO: CHECK UNITS FOR POSITION.
            
            obj.state = MotionControllerState.Moving;
            fprintf(obj.Ser, 'CONT1:AXIS(%d):POS:COMM %f\n', axis, position);
            fprintf(obj.Ser, 'CONT1:AXIS(%d):MOT:STAR', axis);
            waitPosition(axis, position);
            obj.state = MotionControllerState.Stopped;
        end
        
        function waitPosition(axis, position)
            % TODO: Do we need both this and waitIdle()?
        end
        
        function waitIdle(axis)
            % TODO
        end

        function pos = getPosition(obj, axis)
            %getPosition Returns the current position of an axis as a
            %double.

            fprintf(obj.Ser, 'CONT1:AXIS(%d):POS:CURR?', axis);
            posChar = char(fread(obj.Ser, 100))';
            % TODO: MATLAB suggests this instead (I think):
            %posChar = fread(obj.Ser, 100, '*char')';
            pos = str2double(convertCharsToStrings(posChar));
        end

        function vel = getVelocity(obj, axis)
            %getVelocity returns the current velocity of an axis as a
            %double.

            fprintf(obj.Ser, 'CONT1:AXIS(%d):VEL:CURR?', axis);
            velChar = char(fread(obj.Ser, 100))';
            % TODO: MATLAB suggests this instead (I think):
            %velChar = fread(obj.Ser, 100, '*char')';
            vel = str2double(convertCharsToStrings(velChar));
        end
        
        function status = getStatus(obj, axis)
            %getStatus Gets and returns the current status values of Axis.
            %   Axis status is returned as an integer representing a 16-bit number,
            %   where each bit has a respective meaning for the axis status options.
            %   This function gets that value, and decodes each bit, returning a list
            %   of the different status values of the axis at a moment in time.
            %   Details on page 3-42 of MI-4192 Manual.

            fprintf(MI4190, 'CONT1:AXIS(%d):STAT?', axis);
            currStat = char(fread(obj.Ser, 100))';
            % TODO: MATLAB suggests this instead (I think):
            %currStat = fread(obj.Ser, 100, '*char')';

            decStat = str2double(regexp(currStat,'\d*','match'));

            % TODO: Figure out whether this code is correct. This is just
            % copied from Austin's code.

            binStat = dec2bin(decStat) - '0';
            binStat = [zeros(1,12 - length(binStat) + 1) binStat];
            idx = 12; % bits 13, 14, and 15 of status are unused.
            for i = binStat
                if (i == 1)
                    switch idx
                        case 12
                            currStat = [currStat 'Status Changed., '];
                        case 11
                            currStat = [currStat 'Property Changed, '];
                        case 10
                            currStat = [currStat 'Position Trigger Active'];
                        case 9
                            currStat = [currStat 'Axis is Indexed, '];
                        case 8
                            currStat = [currStat 'Axis is Active, '];
                        case 7
                            currStat = [currStat 'Axis in Motion, '];
                        case 6
                            currStat = [currStat 'Error Limit Active, '];
                        case 5
                            currStat = [currStat 'Axis Enabled, '];
                        case 4
                            currStat = [currStat 'PAU Fault, '];
                        case 3
                            currStat = [currStat 'Forward Limit Active, '];
                        case 2
                            currStat = [currStat 'Reverse Limit Active, '];
                        case 1
                            currStat = [currStat 'Home Switch Active, '];
                        case 0
                            currStat = [currStat 'Latch is Set, '];
                        otherwise
                            currStat = [currStat 'Error in status decoding!'];    
                    end
                end % end if

                idx = idx - 1;
            end % end for
            
            status = currStat;
        end % end getStatus()
    end % end methods
end