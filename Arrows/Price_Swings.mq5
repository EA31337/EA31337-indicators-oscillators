//+------------------------------------------------------------------+
//|                                               EA31337 indicators |
//|                                 Copyright 2016-2023, EA31337 Ltd |
//|                                        https://ea31337.github.io |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * @file
 * Implements Price Swings Oscillator.
 */

// Includes.
#include <EA31337-classes/Indicator.mqh>

// Properties.
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_label1  "Swing High"
#property indicator_label2  "Swing Low"

// Indicator parameters
input int swingLookbackPeriod = 50;  // Number of bars to look back for swing detection

// Define indicator buffers
double HighBuffer[];
double LowBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set indicator short name
    IndicatorShortName("Price Swings Oscillator");

    // Set indicator labels
    SetIndexLabel(0, "High Points");
    SetIndexLabel(1, "Low Points");

    // Set buffer arrays
    SetIndexBuffer(0, HighBuffer);
    SetIndexBuffer(1, LowBuffer);

    // No additional calculations needed
    SetIndexEmptyValue(0, 0);
    SetIndexEmptyValue(1, 0);

    if (!ArrayGetAsSeries(HighBuffer)) {
      ArraySetAsSeries(HighBuffer, true);
      ArraySetAsSeries(LowBuffer, true);
    }

    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int lookbackBars = fmin(swingLookbackPeriod, rates_total);

    for (int i = prev_calculated; i < rates_total && !IsStopped(); i++)
    {
        HighBuffer[i] = 0;
        LowBuffer[i] = 0;

        if (i >= lookbackBars - 1)
        {
            int highestHigh = iHighest(NULL, 0, MODE_HIGH, lookbackBars, i - lookbackBars + 1);
            int lowestLow = iLowest(NULL, 0, MODE_LOW, lookbackBars, i - lookbackBars + 1);

            if (high[i] > high[highestHigh] && high[i] > high[i - 1])
            {
                HighBuffer[i] = high[highestHigh];
            }

            if (low[i] < low[lowestLow] && low[i] < low[i - 1])
            {
                LowBuffer[i] = low[lowestLow];
            }
        }
    }

    return(rates_total);
}
