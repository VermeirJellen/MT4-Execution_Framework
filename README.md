##METATRADER 4 - BACKTEST AND EXECUTION FRAMEWORK

This mql4-framework consists of a few dedicated modules that are linked together in order to assist the user with rapid prototyping and testing of simple TA forex strategies. An example expert advisor is also added for demonstration purposes. Note that the project was created before the object oriented refactoring of the mql4 language: Backward compatibility ensures that all functionality remains valid.

###USAGE
To create an expert advisor, the user must copy and overwrite the main expert .mq4 file and the "trading criterion" include file that contains the actual trading logic.

- View `experts/Skeleton.mq4`: This module links all the other modules in the framework together. When creating a new Expert Advisor (eg, trading bot), the user should first copy and rename this file and subsequently place it in the `./experts` folder. Next, Line 37 of the file should be modified in such a way that it links to the "trading criterion" include file of the new expert advisor. View `experts/MomentumEA.mq4` for an example.
- View `include/TradingCriterionSkeleton.mqh`: This module contains the functions with the trading logic that should be defined by the user. The user should copy and rename this file and place it in the `./include` directory. Trading criterion functions are documented in the skeleton file and are further discussed in the "TRADING CRITERION FUNCTIONS" section below. View `include/TradingCriterionMomentumEA.mqh` for an example.

Additionally, also view `indicators/Information.mq4`: When this indicator is attached, event logs and debug information are printed on a separate chart window (instead of the journal).

###EXAMPLE
The trading rules for a simple momentum strategy are implemented in `include/TradingCriterionSkeleton.mqh`. The strategy only allows for a maximum of one open trade at any given time. Trading conditions and order modifications are performed at the start of every new bar instead of every tick. The latter condition is enforced by overwriting the framework settings during the initialization procedure.

##### Entry Conditions
- Go long when no other trade is currently active and the difference between the closing price and opening price of the previous bar is greater than `atrMultiplier`* ATR(`atrPeriod`), where `atrMultiplier` and `atrPeriod` are user defined external parameters. 
- Go short when no trade is active and the difference between the opening price and closing price of the previous bar is greater than `atrMultiplier`*ATR(`atrPeriod`).

Additionally, we define the `trailing` distance as the absolute value between the previous bars' opening and closing prices, multiplied by the `trailParameter`. The latter parameter is a user defined external variable and both will be discussed in more detail below.

##### Order Properties
The order properties depend on the `useTrail` parameter. This user defined external parameter defines whether or not the strategy employs a trailing Stoploss level to manage the open market order.

- Opening Price: `Bid` (short) or `Ask` (long).
- Stoploss Level: We first calculate the absolute value of the difference between the opening and closing price and subsequently multiply the result with the `stoplossParameter` or `trailParameter` (depending on `useTrail`). Note that `StoplossParameter` and `trailParameter` are both user defined external parameters. We subtract (long) or add (short) the  calculated value to the `Bid` or `Ask` price to determine our Stoploss level.
- Take Profit Level: if we do not use a trailling stop, then we calculate the Take Profit level in a similar manner as our Stoploss level by using the `takeProfitParameter` as our user defined multiplication factor. The result is added to the Bid price (long), or subtracted from the Ask price (short) to determine our Take Profit Level.
- Lotsize: The lotsize is calculated in such a way that we risk two percent of our current account balance per trade. Note that the calculation depends on the stoploss level of the trade.

##### Trade Management
The trade management rules become active when a trade has been opened for at least three bars. These rules also depend on the `useTrail` parameter:

- Trailing stop: For a long position we subtract the trailing distance from the `Bid` price. If the resulting value is higher than the current Stoploss level then we update the Stoploss level with the new value. For the short scenario, we add the trailing distance to the `Ask` price and perform the comparison.
- No trailing stop: We close the trade when it is in profit.

Hence, when setting the Take Profit level we automatically assume that momentum is over when the Take Profit is not hit after three bars. However, when using a trailing stop we let our winners run as long as possible in order to potentially capture a small trend.
 
##

###FRAMEWORK FUNCTIONS (OVERWRITE)

####Initialization / deinitialization
- `void initTradingModule()`: This function is called one time upon EA initialization. View mql4 documentation for `init()` conditions.
- `void deinitTradingModule()`: This function is called one time upon EA deinitialization. View mql4 documentation for `deinit()` conditions.

####Trading - Entry conditions
- `int criterion()`: This function is called periodically (once every new tick or at the opening of a new bar only, depending on framework settings). The function contains the order entry rules and returns a relevant signal upon detection of an order activation condition.
- `double getInitialStoplossLevel(int operation, int part)`: This function is called when the criterion function signals an event. The function returns the stoploss level of the new order.
- `double getInitialTakeProfitLevel(int operation, int part)`: This function is called when the criterion function signals an event. It returns the take profit level of the new order.
- `double getInitialLotSize(int operation, int part)`: This function is called when the criterion function signals an event. It returns the lotsize for the new order.
- `double getExpirationDate(int operation, int part)`: This function is called when the criterion function signals an event. It returns the expiration date of the new order.

####Trading - Modification conditions

- `bool closePosition(int index)`: This function is called periodically (once every new tick or at the opening of a new bar only, depending on settings) for every active market or pending order. The index parameter uniquely defines the order and the relevant order information can be accessed via the "newOrders" array. This function implements force close conditions and returns true when the order should be closed.
- `double getNewStoplossLevel(int index)`: This function is called periodically for every active market or pending order. It implements conditions for updating the current Stoploss level of the order and returns a new or unmodified Stoploss level.
- `double getNewTakeProfitLevel(int index)`: This function is called periodically for every active market or pending order. It implements conditions for updating the current Take Profit level of the order and returns a new or unmodified Take Profit level.
- `double getNewOpeningPrice(int index)`: This function is called periodically for each active pending order. It implements conditions for updating the current stop/limit level of the order and returns a new or unmodified stop/limit level.
- `double getNewLotsize(int index)`: This function is called periodically for every active market or pending order. It implements conditions for updating the current lotsize of the order and returns a new or unmodified lotsize. Note that this functionality allows to partially close active market orders.
- `double getNewExpirationDate(int index)`: This function is called periodically for every active market or pending order. It implements conditions for updating the current expiration date of the order and returns a new or unmodified expiration date.

####Logging

- `double getOptimizedParameter1()`: This function is only used when tradelogging is enabled during an optimization backtest run and its functionality depends upon the `TradeLogger` settings (view "Framework Settings" Below). The function returns the current value of the first parameter for which optimization is being performed.
- `double getOptimizedParameter2()`: The function returns the current value of the second parameter for which optimization is being performed.

##
###FRAMEWORK SETTINGS
View `settings.png` for an overview on the general framework settings.

- `EAName`: This value uniquely identifies the Expert advisor and is used for logging purposes.
- `EAUniqueID`: This value uniquely identifies the orders that are linked to a particular expert advisor. Note that an Expert Advisor is able to detect its trades upon re-initialization after shutdown.
- `allowedSlippage`: maximum allowed slippage for buy or sell orders (value is multiplied by MODE_POINT).
- `isECN`: Set to true if the broker uses an electronic communication network for order placement. This implies an alternative order placement procedure in the `Trade` module (Stoploss and Take Profit levels must be added separately).
- `evaluateAtOpen`: Set to true if the trading rules and order modification functionality must be performed at the start of a new bar instead of every new tick.
- `printInfo`: Set to true if important debug information should be printed in the journal when running on real time charts. Note that the information will always be displayed when the `Information` indicator is attached.
- `printDebugInfo`: Set to true if important debug information should be printed in the journal during backtesting.
- `checkEvents`: Set to true in order to print specific information about (non-critical) events, such as order placements and modifications. Note that it might be advisable to set the value to false during optimization backtests in order to avoid information overflows.
- `logTrades`: Set to true if detailed order information should be logged in dedicated .csv's inside the ./files directory. The respective filenames are of the form "EAName_ID-LoggingIdValue.csv" during standard backtesting and of the form "EAName_ID-loggingIdValue_optimizedParameter1-value1_optimizedParameter2-value2" during optimization backtesting.
- `loggingId`: This value uniquely identifies the logfiles for a particular backtest run.
- `maxNumberOfSimultaneousTrades`: Enter the maximum number of simultaneous active orders at any given time, if known. (Used for performance purposes in Tradelogger)
- `nrOptimizedParameters`: The amount of parameters for which optimization is taking place during an optimization backtest run. Only used if tradelogging is enabled.
- `optimizedParameter1`: The name of the first variable for which optimization is being performed.
- `optimizedParameter2`: The name of the second variable for which optimization is being performed.
- VARIABLES FOR TRADING MODULE: A list of parameters representing the EA-specific external parameters / settings. 

##
### LICENSING
Copyright 2015 Jellen Vermeir.
jellenvermeir@gmail.com	

Metatrader 4 - Backtest and Execution Framework is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
Metatrader 4 - Backtest and Execution Framework is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with Actuarial Statistics project. If not, see <http://www.gnu.org/licenses/>.
##