function conditions = plotHistogramSegment(DataToPlot, DataToFlag, Args)
    % Generalized function to plot a segmented histogram based on conditions
    % Supports multiple outlier removal methods.
    
    arguments
        DataToPlot (:,1) double
        DataToFlag (:,1) double
        Args.conditions = {DataToFlag < 25, DataToFlag >= 25 & DataToFlag < 45}
        Args.labels  = {'$rms < 25$', '$25 \leq rms < 45$'}
        Args.StepSize (1,1) double = 0.1
        Args.colors (:,3) double = lines(2)
        Args.outlierMethod (1,:) char {mustBeMember(Args.outlierMethod, ...
            {'percentiles', 'median', 'mean', 'quartiles', 'grubbs', 'gesd'})} = 'percentiles'
        Args.outlierParams (1,:) double = [10, 90] % Parameters for the chosen outlier method
        Args.Xlabel = '$\mu_\alpha$ $\mathrm{KMT - Gaia [mas/yr]}$';
        Args.Ylabel = 'Counts';
        Args.NewFigure = true;
        Args.StdInLegend = true;
    end

    % Step 1: Outlier Removal
    switch Args.outlierMethod
        case 'percentiles'
            % Remove outliers based on percentiles
            lowerP = Args.outlierParams(1);
            upperP = Args.outlierParams(2);
            flagOut = isoutlier(DataToPlot, 'percentiles', [lowerP, upperP]);

        case 'median'
            % Remove outliers based on scaled MAD from the median
            flagOut = isoutlier(DataToPlot, 'median');

        case 'mean'
            % Remove outliers based on standard deviations from the mean
            flagOut = isoutlier(DataToPlot, 'mean');

        case 'quartiles'
            % Remove outliers based on interquartile ranges
            flagOut = isoutlier(DataToPlot, 'quartiles');

        case 'grubbs'
            % Remove outliers using Grubbs' test (requires Statistics Toolbox)
            flagOut = isoutlier(DataToPlot, 'grubbs');

        case 'gesd'
            % Remove outliers using the generalized extreme Studentized deviate test
            flagOut = isoutlier(DataToPlot, 'gesd');

        otherwise
            error('Unsupported outlier removal method: %s', Args.outlierMethod);
    end

    % Filter data based on the selected outlier removal method
    DataToPlot = DataToPlot(~flagOut);
    DataToFlag = DataToFlag(~flagOut);

    if Args.StdInLegend
        for Icond = 1:numel(Args.conditions)
            cond = Args.conditions{Icond};
            StdPerCon(Icond) = tools.math.stat.rstd(DataToPlot(cond(~flagOut)));
            Args.labels{Icond} = [Args.labels{Icond}, ' , rstd = ' num2str(StdPerCon(Icond))];
        end
    end

    % Step 2: Adjust conditions for non-outliers
    adjustedConditions = cellfun(@(cond) cond(~flagOut), Args.conditions, 'UniformOutput', false);

    % Step 3: Define histogram bin edges
    if Args.StepSize < 1
        logSS = floor(log10(Args.StepSize));
        x1 = floor(min(DataToPlot) * 10^(-logSS)) * 10^logSS;
        x1 = x1 - mod(x1, Args.StepSize);
        x2 = ceil(max(DataToPlot) * 10^(-logSS)) * 10^logSS;
        x2 = x2 + mod(x2, Args.StepSize);
        edges = x1:Args.StepSize:x2;
    else
        x1 = floor(min(DataToPlot));
        x2 = ceil(max(DataToPlot));
        edges = x1:Args.StepSize:x2;
    end

    % Step 4: Initialize matrix to store counts for each condition
    countsByCondition = zeros(length(adjustedConditions), numel(edges) - 1);

    % Step 5: Calculate histogram counts for each condition
    for i = 1:length(adjustedConditions)
        % Logical index for the current condition
        idx = adjustedConditions{i};

        % Extract data for the current condition
        subsetData = DataToPlot(idx);

        % Calculate histogram counts for this condition
        counts = histcounts(subsetData, edges);

        % Store counts
        countsByCondition(i, :) = counts;
    end

    % Step 6: Create stacked bar plot
    if Args.NewFigure
        figure;
    end
    hold on;
    binCenters = edges(1:end-1) + diff(edges) / 2; % Convert edges to bin centers
    b = bar(binCenters, countsByCondition', 'stacked', 'BarWidth', 1); % Stacked bar

    % Step 7: Apply colors to each segment
    for i = 1:length(b)
        b(i).FaceColor = 'flat';
        b(i).CData = repmat(Args.colors(i, :), size(b(i).CData, 1), 1); % Assign colors
    end

    % Step 8: Customize plot
    xlabel(Args.Xlabel); % LaTeX-style x-axis label
    ylabel(Args.Ylabel, 'Interpreter', 'latex'); % LaTeX-style y-axis label
    legend(Args.labels, 'Interpreter', 'latex', 'Location', 'Best', 'FontSize', 9); % LaTeX-style legend
    hold off;

    conditions = Args.conditions;
end