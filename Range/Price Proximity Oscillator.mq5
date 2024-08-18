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

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Green

// Define indicator buffers
double HighProximityBuffer[];
double LowProximityBuffer[];

#ifdef __MQL__
#property copyright "2016-2024, EA31337 Ltd"
#property link "https://ea31337.github.io"
#property description INDI_FULL_NAME
#endif

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  // Set indicator label
  IndicatorShortName(INDI_SHORT_NAME);

  // Set indicator buffers
  SetIndexBuffer(0, HighProximityBuffer);
  SetIndexBuffer(1, LowProximityBuffer);

  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
  // Calculate daily high and low
  double daily_high = High[0];
  double daily_low = Low[0];

  // Calculate proximity in percentage
  double high_proximity =
      100.0 * (daily_high - close[0]) / (daily_high - daily_low);
  double low_proximity =
      100.0 * (close[0] - daily_low) / (daily_high - daily_low);

  // Set indicator values in buffers
  HighProximityBuffer[0] = high_proximity;
  LowProximityBuffer[0] = low_proximity;

  return (rates_total);
}
