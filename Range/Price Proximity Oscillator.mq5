//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                                 Copyright 2016-2024, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @file
 * Implements Price Proximity Oscillator.
 */

// Defines.
#define INDI_FULL_NAME "Price Proximity Oscillator"
#define INDI_SHORT_NAME "PPO"

// Indicator properties.
#ifdef __MQL__
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "Low Proximity"
#property indicator_label2  "High Proximity"
#property indicator_color1  clrRed
#property indicator_color2  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_style2  STYLE_SOLID
#property indicator_width1  2
#property indicator_width2  2
#endif

// Indicator buffers.
double HighProximityBuffer[];
double LowProximityBuffer[];

#ifdef __MQL__
#property copyright "2016-2024, EA31337 Ltd"
#property link "https://ea31337.github.io"
#property description INDI_FULL_NAME
#endif

// Includes.
#include <EA31337-classes/Indicator.define.h>

// Input parameters.
input ENUM_TIMEFRAMES InTf = PERIOD_H1; // Timeframe for proximity calculation.
input ENUM_APPLIED_PRICE InAppliedPrice = PRICE_CLOSE; // Price type for calculation.

/**
 * Initizalization.
 */
int OnInit()
  {
   // Indicator buffers mapping
   SetIndexBuffer(0, LowProximityBuffer);
   SetIndexBuffer(1, HighProximityBuffer);

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrRed);

   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrBlue);

   return(INIT_SUCCEEDED);
  }

/**
 * Proximity calculation function.
 */
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
  {
   //--- calculate start position
   int start = prev_calculated > 0 ? prev_calculated - 1 : 0;

   //--- main loop
   for (int i = start; i < rates_total; i++)
     {
      // Find the corresponding bar in the external timeframe
      int corresponding_bar = iBarShift(NULL, InTf, time[i]);

      if(corresponding_bar == -1)
         continue; // If no corresponding bar, skip calculation

      // Get the high and low of the corresponding bar in the selected timeframe
      double highestHigh = iHigh(NULL, InTf, corresponding_bar);
      double lowestLow = iLow(NULL, InTf, corresponding_bar);

      // Calculate the price based on the selected InAppliedPrice
      double currentPrice = iCustomPrice(NULL, InTf, corresponding_bar, InAppliedPrice);

      // Calculate proximity percentages
      if(highestHigh != lowestLow) // Prevent division by zero
      {
         LowProximityBuffer[i] = (currentPrice - lowestLow) / (highestHigh - lowestLow) * 100.0;
         HighProximityBuffer[i] = (highestHigh - currentPrice) / (highestHigh - lowestLow) * 100.0;
      }
      else
      {
         LowProximityBuffer[i] = 50.0;
         HighProximityBuffer[i] = 50.0;
      }
     }

   return(rates_total);
  }

/**
 * Custom function to get the price based on ENUM_APPLIED_PRICE.
 */
double iCustomPrice(const string symbol, ENUM_TIMEFRAMES timeframe, int index, ENUM_APPLIED_PRICE _ap)
  {
   switch(_ap)
     {
      case PRICE_CLOSE:      return iClose(symbol, timeframe, index);
      case PRICE_OPEN:       return iOpen(symbol, timeframe, index);
      case PRICE_HIGH:       return iHigh(symbol, timeframe, index);
      case PRICE_LOW:        return iLow(symbol, timeframe, index);
      case PRICE_MEDIAN:     return (iHigh(symbol, timeframe, index) + iLow(symbol, timeframe, index)) / 2.0;
      case PRICE_TYPICAL:    return (iHigh(symbol, timeframe, index) + iLow(symbol, timeframe, index) + iClose(symbol, timeframe, index)) / 3.0;
      case PRICE_WEIGHTED:   return (iHigh(symbol, timeframe, index) + iLow(symbol, timeframe, index) + 2 * iClose(symbol, timeframe, index)) / 4.0;
      default:               return iClose(symbol, timeframe, index);  // Default to close price.
     }
  }
