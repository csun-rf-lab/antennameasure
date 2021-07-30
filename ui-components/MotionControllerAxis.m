classdef MotionControllerAxis < matlab.ui.componentcontainer.ComponentContainer
    % Controls for a single motion axis
    % appdesigner.customcomponent.configureMetadata('/home/pelmear/anechoic/antenna-measure/ui-components/MotionControllerAxis.m');

    % Public properties
    properties
        Moving {validateattributes(Moving, ...
            {'logical'}, {})} = false;
        Fault {validateattributes(Fault, ...
            {'logical'}, {})} = false;
        AxisPosition {validateattributes(AxisPosition, ...
            {'double'}, {})} = 0;
        TargetPosition {validateattributes(TargetPosition, ...
            {'double'}, {})} = 0;
    end

    % Events
    events (HasCallbackProperty, NotifyAccess = protected)
        MoveToBtnPushed     % MoveToBtnPushedFcn
        PlusFiveBtnPushed   % PlusFiveBtnPushed
        MinusFiveBtnPushed  % MinusFiveBtnPushed
    end

    % Private properties
    properties (Access = private, Transient, NonCopyable)
        GridLayout                    matlab.ui.container.GridLayout
        AxisPositionLabel             matlab.ui.control.Label
        Panel                         matlab.ui.container.Panel
        MiddleGrid                    matlab.ui.container.GridLayout
        PlusFiveBtn                   matlab.ui.control.Button
        MinusFiveBtn                  matlab.ui.control.Button
        MovetoButton                  matlab.ui.control.Button
        TargetPositionEditFieldLabel  matlab.ui.control.Label
        TargetPositionEditField       matlab.ui.control.NumericEditField
        RightGrid                     matlab.ui.container.GridLayout
        AxisFaultLamp                 matlab.ui.control.Lamp
        FaultLampLabel                matlab.ui.control.Label
        AxisMovingLamp                matlab.ui.control.Lamp
        MovingLampLabel               matlab.ui.control.Label
    end

    methods (Access = protected)
        function setup(obj)
            % Create GridLayout
            obj.GridLayout = uigridlayout(obj);
            obj.GridLayout.ColumnWidth = {'1x', '2x', '1x'};
            obj.GridLayout.RowHeight = {'1x'};

            % Axis label
            obj.AxisPositionLabel = uilabel(obj.GridLayout);
            obj.AxisPositionLabel.HorizontalAlignment = 'center';
            obj.AxisPositionLabel.FontSize = 24;
            obj.AxisPositionLabel.FontWeight = 'bold';
            obj.AxisPositionLabel.Layout.Row = 1;
            obj.AxisPositionLabel.Layout.Column = 1;
            obj.AxisPositionLabel.Text = '+ 0.00';

            % Middle panel
            obj.Panel = uipanel(obj.GridLayout);
            obj.Panel.Layout.Row = 1;
            obj.Panel.Layout.Column = 2;

            % Middle grid
            obj.MiddleGrid = uigridlayout(obj.Panel);
            obj.MiddleGrid.ColumnWidth = {'1x', '1x', '1x'};

            % TargetPositionEditField
            obj.TargetPositionEditField = uieditfield(obj.MiddleGrid, 'numeric');
            obj.TargetPositionEditField.Layout.Row = 1;
            obj.TargetPositionEditField.Layout.Column = 2;
            obj.TargetPositionEditField.ValueChangedFcn = @(o,e) obj.handleTargetPositionChange();

            % TargetPositionEditFieldLabel
            obj.TargetPositionEditFieldLabel = uilabel(obj.MiddleGrid);
            obj.TargetPositionEditFieldLabel.HorizontalAlignment = 'right';
            obj.TargetPositionEditFieldLabel.Layout.Row = 1;
            obj.TargetPositionEditFieldLabel.Layout.Column = 1;
            obj.TargetPositionEditFieldLabel.Text = 'Target Position';

            % MovetoButton
            obj.MovetoButton = uibutton(obj.MiddleGrid, 'push');
            obj.MovetoButton.Layout.Row = 2;
            obj.MovetoButton.Layout.Column = 2;
            obj.MovetoButton.Text = 'Move to';
            obj.MovetoButton.ButtonPushedFcn = @(o,e) obj.handleMoveToBtn();

            % PlusFiveBtn
            obj.PlusFiveBtn = uibutton(obj.MiddleGrid, 'push');
            obj.PlusFiveBtn.Layout.Row = 1;
            obj.PlusFiveBtn.Layout.Column = 3;
            obj.PlusFiveBtn.Text = '+ 5';
            obj.PlusFiveBtn.ButtonPushedFcn = @(o,e) obj.handlePlusFiveBtn();

            % MinusFiveBtn
            obj.MinusFiveBtn = uibutton(obj.MiddleGrid, 'push');
            obj.MinusFiveBtn.Layout.Row = 2;
            obj.MinusFiveBtn.Layout.Column = 3;
            obj.MinusFiveBtn.Text = '- 5';
            obj.MinusFiveBtn.ButtonPushedFcn = @(o,e) obj.handleMinusFiveBtn();

            % Right grid
            obj.RightGrid = uigridlayout(obj.GridLayout);
            obj.RightGrid.Layout.Row = 1;
            obj.RightGrid.Layout.Column = 3;

            % MovingLampLabel
            obj.MovingLampLabel = uilabel(obj.RightGrid);
            obj.MovingLampLabel.HorizontalAlignment = 'right';
            obj.MovingLampLabel.Layout.Row = 1;
            obj.MovingLampLabel.Layout.Column = 1;
            obj.MovingLampLabel.Text = 'Moving';

            % AxisMovingLamp
            obj.AxisMovingLamp = uilamp(obj.RightGrid);
            obj.AxisMovingLamp.Layout.Row = 1;
            obj.AxisMovingLamp.Layout.Column = 2;
            obj.AxisMovingLamp.Color = [0.8 0.8 0.8];

            % FaultLampLabel
            obj.FaultLampLabel = uilabel(obj.RightGrid);
            obj.FaultLampLabel.HorizontalAlignment = 'right';
            obj.FaultLampLabel.Layout.Row = 2;
            obj.FaultLampLabel.Layout.Column = 1;
            obj.FaultLampLabel.Text = 'Fault';

            % Axis1FaultLamp
            obj.AxisFaultLamp = uilamp(obj.RightGrid);
            obj.AxisFaultLamp.Layout.Row = 2;
            obj.AxisFaultLamp.Layout.Column = 2;
            obj.AxisFaultLamp.Color = [0.8 0.8 0.8];
        end

        function update(obj)
%             % Update edit field and button colors
%             set([obj.EditField obj.Button], 'BackgroundColor', obj.Value, ...
%                 'FontColor', obj.getContrastingColor(obj.Value));
% 
%             % Update the display text
%             obj.EditField.Value = num2str(obj.Value, '%0.2g ');

            obj.updateMovingBtn();
            obj.updateFaultBtn();
            obj.updatePositionLabel();
        end
    end

    methods (Access = private)
        function handleMoveToBtn(obj)
            % I think we could use a custom event object here
            % to pass the desired position, but that seems complicated,
            % so we'll just rely on the container to check the
            % TargetPosition.
            notify(obj, "MoveToBtnPushed");
        end

        function handlePlusFiveBtn(obj)
            notify(obj, "PlusFiveBtnPushed");
        end

        function handleMinusFiveBtn(obj)
            notify(obj, "MinusFiveBtnPushed");
        end

        function handleTargetPositionChange(obj)
            obj.TargetPosition = obj.TargetPositionEditField.Value;
        end

        function updateMovingBtn(obj)
            if obj.Moving
                obj.AxisMovingLamp.Color = 'green';
            else
                obj.AxisMovingLamp.Color = [0.80, 0.80, 0.80];
            end
        end

        function updateFaultBtn(obj)
            if obj.Fault
                obj.AxisFaultLamp.Color = 'red';
            else
                obj.AxisFaultLamp.Color = [0.80, 0.80, 0.80];
            end
        end

        function updatePositionLabel(obj)
            if obj.AxisPosition >= 0
                pos = sprintf("+ %.03f", obj.AxisPosition);
            else
                pos = sprintf("- %.03f", -1*obj.AxisPosition);
            end

            obj.AxisPositionLabel.Text = pos;
        end
    end
end