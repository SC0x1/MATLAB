function varargout = StripChartXY(mode,varargin)
%STRIPCHARTXY provides scrolling display of streaming data.
%   This strip chart is a special kind of XY plot meant to convey recent
%   history of a waveform, such as voltage over time by dynamic updates
%   with new data. 
% 
%	StripChartXY is slightly different from StripChart - the useage is a
%	little different and StripChartXY plot x,y data pairs (made for if you
%	care about the actual x-value)
% 
%	The strip chart must be properly initialized and updated, so there are 
%	2 operating modes.
%
%   STRIPCHART(MODE,...) where MODE can be 'Initialize' or 'Update'. The
%   additional arguments depend on MODE.
%
%   hLine = STRIPCHART('Initialize',nPts) 
%		sets up the strip chart with NaN data of length nPts.
%		just plot one line
%   hLines = STRIPCHART('Initialize',nPts,numlines) 
%		same as above, but for plotting multiple lines
%
%   STRIPCHART('Update',hLine,xnew,ynew) 
% 		updates the strip chart with new data.
% 		xnew & ynew are M-length vectors.  M new points get added to the right.
% 		Everything else shifts left. The M oldest points are discarded. 
%		If the initially defined number of points, N is less than M, then 
%		only the most recent N points are used for the update.
%   STRIPCHART('Update',hLine,xnew,ynew,'zoom') 
%		same as above, but zoom in so data always fills plot
%		useful if nPts is very large
%		only different until number of points on plot equals nPts
% 
%   Example with one line:
%		nPts = 1000;	% number of points to display on stripchart
% 		hLine = StripChartXY('Initialize',nPts);
% 		x = 1:nPts*2;
% 		y = sin(2*pi*x/nPts);
% 		for i=1:numel(x)
%			StripChartXY('Update',hLine,x(i),y(i))
%			% StripChartXY('Update',hLine,x(i),y(i),'zoom')
% 		end
%
%	Example with multiple lines:
% 		nPts = 1000;	% number of points to display on stripchart
% 		hLines = StripChartXY('Initialize',nPts,3);	% setup for 3 lines
% 		x = 1:nPts*2;
% 		y1 = sin(2*pi*x/nPts);
% 		y2 = cos(2*pi*x/nPts);
% 		y3 = y1.^2;
% 		for m=1:numel(x)
% 			StripChartXY('Update',hLines(1),x(m),y1(m))
% 			StripChartXY('Update',hLines(2),x(m),y2(m))
% 			StripChartXY('Update',hLines(3),x(m),y3(m))
% 		end
% 
%   NOTE:
%       For initialization details type HELP STRIPCHARTXY/INITIALIZE
%       For update details type HELP STRIPCHARTXY/UPDATE
% 
%	version info:
%	v0 - The file StripChart.m was written by Robert Bemis and is the basis of
%		>95% of this slightly modified version.
%		http://www.mathworks.com/matlabcentral/fileexchange/3356-strip-chart
%	v1 - Nathan Tomlin slightly modified Robert's file and renamed it.
%	

% Copyright 2003-2010 The MathWorks, Inc.


%input argument checking and parsing
switch lower(mode)
	case 'initialize'
	    hLine = initialize(varargin);  %INITIALIZE(HAXES)
	    varargout{1} = hLine;
	case 'update'
		update(varargin);  %UPDATE(HLINE,xnew,ynew)
	otherwise
		error(['invalid mode ',mode])
end


%--------------------------------------------------------------------------
function hLine = initialize(varargin)
%INITIALIZE axes to plot dummy data (NaN) of nPts length
%       Double buffering is enforced on its parent figure.

varargin = varargin{1};
nPts = varargin{1};
if numel(varargin) == 2	% optional input - exists
	numlines = varargin{2};
else	% optional input - if missing, set to default
	numlines = 1;
end

% check inputs
if ~isa(nPts,'numeric') || numel(nPts) ~= 1
% if ~isa(nPts,'numeric')
	error('invalid nPts input')
end
if ~isa(numlines,'numeric') || numel(numlines) ~= 1
	error('invalid numlines input')
end

% dummy data of correct size - NaN values don't show up on plot
dummydata = ones(1,nPts)*NaN;

% new figure - plot with dummy data
figure; 
% hold on
hold all
for m = 1:numlines
	hLine(m) = plot(dummydata,dummydata);
end

% turn on doublebuffer - makes plot smoother
hAxes = gca;
hfig = get(hAxes,'parent');
set(hfig,'DoubleBuffer','on');


%--------------------------------------------------------------------------
% function update(hLine,xnew,ynew)
function update(varargin)
%UPDATE strip chart with new x&y data.
%   UPDATE(HLINE,xnew,ynew) adds new data to the specified line plot.
%       HLINE must be a valid line handle.
%       xnew & ynew are N-length vectors of new X & Y values.
%       The N new points append to right (N oldest points discarded).

varargin = varargin{1};
hLine = varargin{1};
xnew = varargin{2};
ynew = varargin{3};
if numel(varargin) == 4 && strcmpi(varargin{4},'zoom')
	dozoom = 1;	% zoom in on data when first filling plot
else
	dozoom = 0;	% don't zoom in when filling plot
end

% check inputs
if ~ishandle(hLine), error('invalid lineseries handle'), end
if ~strmatch(get(hLine,'type'),'line'), error('invalid HLINE'), end
% make sure only one line, not array of handles
if length(hLine)>1, error('hLine must be scalar, not array'), end
if ~all(ishandle(hLine)), return, end

% get old data from plot
xData = get(hLine,'XData');     % old x data
yData = get(hLine,'YData');     % old y data
nPts = length(xnew);			% how much new data

if nPts>length(xData)                   % more new data than original
  nPts = length(xData);                 % only keep last part
  xnew = xnew(end-nPts+1:nPts);
  ynew = ynew(end-nPts+1:nPts);
end

% fix up data to change plot
xData(1:end-nPts) = xData(nPts+1:end);  % shift old data left
xData(end-nPts+1:end) = xnew;        % new data goes on right
yData(1:end-nPts) = yData(nPts+1:end);  % shift old data left
yData(end-nPts+1:end) = ynew;        % new data goes on right

% updata plot with new data
% if ~ishandle(hLine), return, end
set(hLine,'XData',xData)                % update plot
set(hLine,'YData',yData)                % update plot
drawnow                                 % refresh display


% deal with x-limits to make data scrolling smoother
% two separate cases:
%	1. while filling in initial plot - guess xlimits from data and set
%		(default) - do not do if 'zoom' option passed
%	2. while scrolling data - set xlimits to data
hAxes = get(gcf,'CurrentAxes');
if any(isnan(xData))	% still filling up plot, not yet sliding
	if dozoom == 0
		% while filling plot, want to guess xlim from xdata
		idata = find(~isnan(xData));	% index of all data (not NaN values)
		if numel(idata) > 1
			xDataReal = xData(idata);
			dx = mean(diff(xDataReal));	% find average delta-x
			xmin = min(xDataReal);
			xmax = max([max(xDataReal),xmin+numel(xData)*dx-1]);
				% don't want to ever clip data in case of weird x spacing
			xlim(hAxes,[xmin,xmax])	% set xlimits
		end
	end
else	% no NaN values - data sliding to left
	xlim(hAxes,[min(xData),max(xData)])
end