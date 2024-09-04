//+------------------------------------------------------------------+
//|                                                          EA31337 |
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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * @file
 * Implements Account Stats indicator.
 */

// Defines.
#define INDI_FULL_NAME "Spread"
#define INDI_SHORT_NAME "Spread"

// Indicator properties.
#ifdef __MQL__
  #property copyright "2016-2023, EA31337 Ltd"
  #property link "https://ea31337.github.io"
  #property description INDI_FULL_NAME
  //--
  #property indicator_separate_window
  #property indicator_buffers 1
  #property indicator_plots 1
  #property indicator_type1 DRAW_LINE
  #property indicator_color1 Blue
  #property indicator_width1 2
  #property indicator_label1 "Spread"
  #property version "1.000"
#endif

// Includes.
#include <EA31337-classes/Std.h>

// Includes.
#include <EA31337-classes/Indicator.mqh>
#include <EA31337-classes/SymbolInfo.mqh>

// Spread calculation method.
enum ENUM_SPREAD_METHOD {
  SPREAD_METHOD_SYMBOL_INFO,
  SPREAD_METHOD_ASK_BID_DIFF,
  SPREAD_METHOD_COPY_SPREAD,
  SPREAD_METHOD_SPREAD_INPUT_ARRAY,
};

// Input parameters.
input ENUM_SPREAD_METHOD Spread_Method = SPREAD_METHOD_ASK_BID_DIFF;  // Spread Calculation Method
input int Spread_Shift = 0;                                           // Shift

// Global indicator buffers.
double SpreadBuffer[];

// Global variables.
SymbolInfo *symbolinfo;

/**
 * Init event handler function.
 */
void OnInit() {
  // Initialize indicator buffers.
  SetIndexBuffer(0, SpreadBuffer, INDICATOR_DATA);
  // Initialize indicator for the current account.
  symbolinfo = new SymbolInfo();
  string short_name = StringFormat("%s(%d)", INDI_SHORT_NAME, ::Spread_Shift);
  IndicatorSetString(INDICATOR_SHORTNAME, short_name);
  PlotIndexSetString(0, PLOT_LABEL, "Spread (pips)");
  // PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
  // PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, DBL_MAX);
  // Sets first bar from what index will be drawn
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 0);
  // Sets indicator shift.
  PlotIndexSetInteger(0, PLOT_SHIFT, ::Spread_Shift);
  PlotIndexSetInteger(1, PLOT_SHIFT, ::Spread_Shift);
  PlotIndexSetInteger(2, PLOT_SHIFT, ::Spread_Shift);
  PlotIndexSetInteger(3, PLOT_SHIFT, ::Spread_Shift);
  PlotIndexSetInteger(4, PLOT_SHIFT, ::Spread_Shift);
  // Drawing settings (MQL4).
  SetIndexStyle(0, DRAW_LINE);
  SetIndexStyle(1, DRAW_LINE);
  SetIndexStyle(2, DRAW_LINE);
  SetIndexStyle(3, DRAW_LINE);
  SetIndexStyle(4, DRAW_LINE);
}

/*
  - How reliable is the spread[]?

  - What about CopySpread() in MQL5 and CopyRates() in MQL4?
    In MQ5 we can use CopyRates().
  https://www.mql5.com/en/docs/constants/structures/mqlrates

  Taking spread:
  - double spread =
  (double)(SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)/MathPow(10,_Digits));
*/

/**
 * Calculate event handler function.
 */
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
  int i, _spread_buf[], _num_spreads;

  if (rates_total <= 0) {
    return (0);
  }

  // ACQUIRE_BUFFER1(SpreadBuffer); // @todo: To add in further versions.

  if (prev_calculated == 0) {
    // Clearing buffer for testing purposes.
    ArrayInitialize(SpreadBuffer, 0);

    switch (Spread_Method) {
      case SPREAD_METHOD_SYMBOL_INFO:
      case SPREAD_METHOD_ASK_BID_DIFF:
      case SPREAD_METHOD_COPY_SPREAD:
        _num_spreads = CopySpread(Symbol(), PERIOD_CURRENT, ::Spread_Shift, rates_total, _spread_buf);

        if (_num_spreads != rates_total) {
          Alert("Error: CopySpread() failed. Insufficient data. Requested ", rates_total, " items, but got only ",
                _num_spreads, ". Error = ", GetLastError(), ".");
          DebugBreak();
        }

        // We will copy _spread_buf into SpreadBuffer memory-wise.
        ArraySetAsSeries(_spread_buf, false);
        for (i = 0; i < rates_total; i++) {
          SpreadBuffer[i] = _spread_buf[i];
        }
        break;

      case SPREAD_METHOD_SPREAD_INPUT_ARRAY:
        // Copying input spread[] directly into SpreadBuffer.
        for (i = 0; i < rates_total; i++) {
          SpreadBuffer[i] = spread[i];
        }
        break;

      default:
        Alert("Error: Invalid spread method passes into Spread_Method!");
        DebugBreak();
    }
  } else {
    int _spread;
    double _ask, _bid;

    switch (Spread_Method) {
      case SPREAD_METHOD_SYMBOL_INFO:
        _spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
        break;

      case SPREAD_METHOD_ASK_BID_DIFF:
        _ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        _bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        _spread = (int)MathRound((_ask - _bid) * pow(10, symbolinfo.GetDigits()));
        break;

      case SPREAD_METHOD_COPY_SPREAD:
        if (CopySpread(_Symbol, 0, ::Spread_Shift, 1, _spread_buf) != 1) {
          Alert(
              "Error: CopySpread() failed. Insufficient data. Requested 1 "
              "item, but got 0. Error = ",
              GetLastError(), ".");
          DebugBreak();
        }
        _spread = _spread_buf[0];
        break;

      case SPREAD_METHOD_SPREAD_INPUT_ARRAY:
        _spread = spread[rates_total - 1];
        break;

      default:
        Alert("Error: Invalid spread method passes into Spread_Method!");
        DebugBreak();
    }

    SpreadBuffer[rates_total - 1] = _spread;
  }

  // RELEASE_BUFFER1(SpreadBuffer); // @todo: To add in further versions.

  // Returns new prev_calculated.
  return (rates_total);
}

/**
 * Deinit event handler function.
 */
void OnDeinit(const int reason) { delete symbolinfo; }
