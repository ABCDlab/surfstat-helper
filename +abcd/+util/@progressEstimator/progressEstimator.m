classdef progressEstimator < handle
    % progressEstimator is a class that simplifies reporting the progress of a long-running process, and can estimate the total duration and time of completion.

    properties
        startedTime = 0;
        elapsedTime = 0;
        total = 1;
        progressPosition = 0;
        intervalSec = 0;
        intervalSecRepeat = false;
        intervalPosition = 0;
        intervalPositionRepeat = false;
        nextNotificationTime = 0;
        nextNotificationPosition = 0;
    end

    properties (Hidden)
    end

    methods
        function obj = progressEstimator(varargin)
            % Create a progressEstimator object
            if (nargin == 1)
                arg = varargin{1};
                if (isa(arg, class(obj)))
                    % pass through
                    obj = arg;
                elseif (isa(arg, 'struct'))
                    f = fieldnames(arg);
                    for i=1:numel(f)
                        name = f{1};
                        obj.setValues(name, arg.(name));
                    end
                end
            elseif (nargin > 1)
                obj.setValues(varargin{:});
            end
        end

        function setValues(obj, varargin)
            % Set value of attribute
            for i=1:2:numel(varargin)
                name = varargin{i};
                value = varargin{i+1};
                assert(any(strcmp(class(value),{'char' 'single' 'double' 'logical'})));
                % fprintf('SET(%s=%s)\n', name, num2str(value));
                obj.(name) = value;
            end
        end

        function start(obj)
            obj.startedTime = now;
            obj.elapsedTime = 0;
            obj.progressPosition = 0;
            if obj.intervalPosition > 0
                obj.nextNotificationPosition = obj.intervalPosition;
            else
                obj.nextNotificationPosition = obj.total;
            end
            if obj.intervalSec > 0
                obj.nextNotificationTime = obj.startedTime + obj.intervalSec/24/60/60;
            else
                obj.nextNotificationTime = obj.startedTime + 1; % one day
            end
        end

        function setProgress(obj, num)
            obj.progressPosition = num;
            obj.checkNotification();
        end

        function checkNotification(obj)
            obj.elapsedTime = now - obj.startedTime;
            if obj.progressPosition > obj.nextNotificationPosition || obj.elapsedTime > obj.nextNotificationTime
                obj.notifyProgress();
                obj.incrementNotification();
            end
        end

        function notifyProgress(obj)
            timeTotalEst = obj.elapsedTime * obj.total / obj.progressPosition;
            timeEndEst = obj.startedTime + timeTotalEst;

            fprintf('%.0f%% complete, @%s/%s, %.1f min elapsed, estimate total time %.1f min, estimate complete at %s\n', obj.progressPosition/obj.total*100, num2str(obj.progressPosition), num2str(obj.total), obj.elapsedTime*24*60, timeTotalEst*24*60, datestr(timeEndEst));
        end

        function incrementNotification(obj)
            if obj.intervalPosition > 0  &&  obj.intervalPositionRepeat
                obj.nextNotificationPosition = obj.nextNotificationPosition + obj.intervalPosition;
            else
                obj.nextNotificationPosition = obj.total;
            end
            if obj.intervalSec > 0  &&  obj.intervalSecRepeat
                obj.nextNotificationTime = now + obj.intervalSec/24/60/60;
            else
                obj.nextNotificationTime = now + 1;
            end
        end
    end
end
