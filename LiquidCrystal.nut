// LiquidCrystal Esquilo library ported from Arduino

require("GPIO");

const LCD_CLEARDISPLAY = 0x01;
const LCD_RETURNHOME = 0x02;
const LCD_ENTRYMODESET = 0x04;
const LCD_DISPLAYCONTROL = 0x08;
const LCD_CURSORSHIFT = 0x10;
const LCD_FUNCTIONSET = 0x20;
const LCD_SETCGRAMADDR = 0x40;
const LCD_SETDDRAMADDR = 0x80;

// flags for display entry mode
const LCD_ENTRYRIGHT = 0x00;
const LCD_ENTRYLEFT = 0x02;
const LCD_ENTRYSHIFTINCREMENT = 0x01;
const LCD_ENTRYSHIFTDECREMENT = 0x00;

// flags for display on/off control
const LCD_DISPLAYON = 0x04;
const LCD_DISPLAYOFF = 0x00;
const LCD_CURSORON = 0x02;
const LCD_CURSOROFF = 0x00;
const LCD_BLINKON = 0x01;
const LCD_BLINKOFF = 0x00;

// flags for display/cursor shift
const LCD_DISPLAYMOVE = 0x08;
const LCD_CURSORMOVE = 0x00;
const LCD_MOVERIGHT = 0x04;
const LCD_MOVELEFT = 0x00;

// flags for function set
const LCD_8BITMODE = 0x10;
const LCD_4BITMODE = 0x00;
const LCD_SPIMODE = 0x20;
const LCD_2LINE = 0x08;
const LCD_1LINE = 0x00;
const LCD_5x10DOTS = 0x04;
const LCD_5x8DOTS = 0x00;


// When the display powers up, it is configured as follows:
//
// 1. Display clear
// 2. Function set:
//    DL = 1; 8-bit interface data
//    N = 0; 1-line display
//    F = 0; 5x8 dot character font
// 3. Display on/off control:
//    D = 0; Display off
//    C = 0; Cursor off
//    B = 0; Blinking off
// 4. Entry mode set:
//    I/D = 1; Increment by 1
//    S = 0; No shift
//
// Note, however, that resetting the Esquilo doesn't reset the LCD, so we
// can't assume that its in that state when a sketch starts (and the
// LiquidCrystal constructor is called).

class LiquidCrystal
{
    _displayfunction = 0;
    _displaycontrol = 0;
    _displaymode = 0;

    _rs_pin = null;
    rs = 0;
    _rw_pin = null;
    rw = 0;
    _enable_pin = null;
    enable = 0;

    _numlines = 2;

    _usingSpi = false;

    _data_pins = array(8, 0);

    constructor(mode, rs, rw, enable, d0, d1, d2, d3, d4, d5, d6, d7)
    {
        if (mode == LCD_8BITMODE) {
            // 8 bit mode
            init(0, rs, rw, enable, d0, d1, d2, d3, d4, d5, d6, d7);
        } else if (mode == LCD_4BITMODE) {
            // 4 bit mode
            init(1, rs, rw, enable, d0, d1, d2, d3, 0, 0, 0, 0);
        } else {
            // SPI mode ##############################
            ssPin = rs;
            initSPI(ssPin);
            // shiftRegister pins 1,2,3,4,5,6,7 represent rs, rw, enable, d4-7 in that order
            // but we are not using RW so RW it's zero or 255
            init(1, 1, 255, 3, 0, 0, 0, 0, 4, 5, 6, 7);
        }
    }

    function init(fourbitmode, rs, rw, enable, d0, d1, d2, d3, d4, d5, d6, d7)
    {
        if (rs != 0 && rs != 255) {
            _rs_pin = GPIO(rs);  // Note we can't use slot assignment here
        }
        if (rw != 0 && rw != 255) {
            _rw_pin = GPIO(rw);
        }
        if (enable != 0) {
            _enable_pin = GPIO(enable);
        }

        if (d0 != 0) {
            _data_pins[0] = GPIO(d0);
        }
        if (d1 != 0) {
            _data_pins[1] = GPIO(d1);
        }
        if (d2 != 0) {
            _data_pins[2] = GPIO(d2);
        }
        if (d3 != 0) {
            _data_pins[3] = GPIO(d3);
        }
        if (d4 != 0) {
            _data_pins[4] = GPIO(d4);
        }
        if (d5 != 0) {
            _data_pins[5] = GPIO(d5);
        }
        if (d6 != 0) {
            _data_pins[6] = GPIO(d6);
        }
        if (d7 != 0) {
            _data_pins[7] = GPIO(d7);
        }

        _rs_pin.output();
        // we can save 1 pin by not using RW. Indicate by passing 255 instead of pin#
        if (rw != 255 && rw != 0) {
            _rw_pin.output();
        }
        _enable_pin.output();

        if (fourbitmode) {
            _displayfunction = LCD_4BITMODE | LCD_1LINE | LCD_5x8DOTS;
        } else {
            _displayfunction = LCD_8BITMODE | LCD_1LINE | LCD_5x8DOTS;
        }

        begin(16, 1, 0);

        // since in initSPI constructor we set _usingSPI to true and we run it first
        // from SPI constructor, we do nothing here otherwise we set it to false
        if (_usingSpi) {
            // SPI ######################################################
            ;
        } else {
            _usingSpi = false;
        }
    }
};

// SPI ##########################################
function LiquidCrystal::initSPI(ssPin)
{
    // initialize SPI:
    local _usingSpi = true;
    local _latchPin = ssPin;
    _latchPin.output();  // just in case _latchPin is not 10 or 53 set it to output
                         // otherwise SPI.begin() will set it to output but just in case

    SPI.begin();

    // set clockDivider to SPI_CLOCK_DIV2 by default which is 8MHz
    _clockDivider = SPI_CLOCK_DIV2;
    SPI.setClockDivider(_clockDivider);

    // set data mode to SPI_MODE0 by default
    _dataMode = SPI_MODE0;
    SPI.setDataMode(_dataMode);

    // set bitOrder to MSBFIRST by default
    _bitOrder = MSBFIRST;
    SPI.setBitOrder(_bitOrder);
}

function LiquidCrystal::begin(cols, lines, dotsize)
{
    if (lines > 1) {
        _displayfunction = _displayfunction | LCD_2LINE;
    }

    local _numlines = lines;
    local _currline = 0;

    // for some 1 line displays you can select a 10 pixel high font
    if ((dotsize != 0) && (lines == 1)) {
        _displayfunction = _displayfunction | LCD_5x10DOTS;
    }

    // SEE PAGE 45/46 FOR INITIALIZATION SPECIFICATION!
    // according to datasheet, we need at least 40ms after power rises above 2.7V
    // before sending commands. Arduino can turn on way befer 4.5V so we'll wait 50
    udelay(50000);
    // Now we pull both RS and R/W low to begin commands
    _rs_pin.low();
    _enable_pin.low();
    if (rw != 0 && rw != 255) {
        _rw_pin.low();
    }

    // put the LCD into 4 bit or 8 bit mode
    if (! (_displayfunction & LCD_8BITMODE)) {
        // this is according to the hitachi HD44780 datasheet
        // figure 24, pg 46

        // we start in 8bit mode, try to set 4 bit mode
        write4bits(0x03);
        udelay(4500);  // wait min 4.1ms

        // second try
        write4bits(0x03);
        udelay(4500);  // wait min 4.1ms

        // third go!
        write4bits(0x03);
        udelay(150);

        // finally, set to 4-bit interface
        write4bits(0x02);
    } else {
        // this is according to the hitachi HD44780 datasheet
        // page 45 figure 23

        // Send function set command sequence
        command(LCD_FUNCTIONSET | _displayfunction);
        udelay(4500);  // wait more than 4.1ms

        // second try
        command(LCD_FUNCTIONSET | _displayfunction);
        udelay(150);

        // third go
        command(LCD_FUNCTIONSET | _displayfunction);
    }

    // finally, set # lines, font size, etc.
    command(LCD_FUNCTIONSET | _displayfunction);

    // turn the display on with no cursor or blinking default
    _displaycontrol = LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF;
    display();

    // clear it off
    clear();

    // Initialize to default text direction (for romance languages)
    _displaymode = LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT;
    // set the entry mode
    command(LCD_ENTRYMODESET | _displaymode);
}

/********** high level commands, for the user! */
function LiquidCrystal::clear()
{
    command(LCD_CLEARDISPLAY);  // clear display, set cursor position to zero
    udelay(2000);  // this command takes a long time!
}

function LiquidCrystal::home()
{
    command(LCD_RETURNHOME);  // set cursor position to zero
    udelay(2000);  // this command takes a long time!
}

function LiquidCrystal::setCursor(col, row)
{
    if (row > _numlines) {
        row = _numlines - 1;    // we count rows starting w/0
    }

    local pos = col;
    if (row == 1) {  // row offsets
        pos += 0x40;
    } else if (row == 2) {
        pos += 0x14;
    } else if (row == 3) {
        pos += 0x54;
    }
    command(LCD_SETDDRAMADDR | pos);
}

// Turn the display on/off (quickly)
function LiquidCrystal::noDisplay()
{
    _displaycontrol = _displaycontrol & ~LCD_DISPLAYON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

function LiquidCrystal::display()
{
    _displaycontrol = _displaycontrol | LCD_DISPLAYON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

// Turns the underline cursor on/off
function LiquidCrystal::noCursor()
{
    _displaycontrol = _displaycontrol & ~LCD_CURSORON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

function LiquidCrystal::cursor()
{
    _displaycontrol = _displaycontrol | LCD_CURSORON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

// Turn on and off the blinking cursor
function LiquidCrystal::noBlink()
{
    _displaycontrol = _displaycontrol & ~LCD_BLINKON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

function LiquidCrystal::blink()
{
    _displaycontrol = _displaycontrol | LCD_BLINKON;
    command(LCD_DISPLAYCONTROL | _displaycontrol);
}

// These commands scroll the display without changing the RAM
function LiquidCrystal::scrollDisplayLeft()
{
    command(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVELEFT);
}

function LiquidCrystal::scrollDisplayRight()
{
    command(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVERIGHT);
}

// This is for text that flows Left to Right
function LiquidCrystal::leftToRight()
{
    _displaymode = _displaymode | LCD_ENTRYLEFT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// This is for text that flows Right to Left
function LiquidCrystal::rightToLeft()
{
    _displaymode = _displaymode & ~LCD_ENTRYLEFT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// This will 'right justify' text from the cursor
function LiquidCrystal::autoscroll()
{
    _displaymode = _displaymode | LCD_ENTRYSHIFTINCREMENT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// This will 'left justify' text from the cursor
function LiquidCrystal::noAutoscroll()
{
    _displaymode = _displaymode & ~LCD_ENTRYSHIFTINCREMENT;
    command(LCD_ENTRYMODESET | _displaymode);
}

// Allows us to fill the first 8 CGRAM locations
// with custom characters
function LiquidCrystal::createChar(location, charmap)
{
    location = location & 0x7;  // we only have 8 locations 0-7
    command(LCD_SETCGRAMADDR | (location << 3));
    local ci;
    for (ci = 0; ci < 8; ci++) {
        write(charmap[ci]);
    }
}

/*********** mid level commands, for sending data/cmds */

function LiquidCrystal::command(value)
{
    send(value, LOW);
}

function LiquidCrystal::write(value)
{
    send(value, HIGH);
    return 1;  // assume success
}

/************ low level data pushing commands **********/

// write either command or data, with automatic 4/8-bit selection
function LiquidCrystal::send(value, mode) {
    if (_usingSpi == false) {
        if (mode) {
            _rs_pin.high();
        } else {
            _rs_pin.low();
        }

        // if there is a RW pin indicated, set it low to Write
        if (rw != 0 && rw != 255) {
            _rw_pin.low();
        }

        if (_displayfunction & LCD_8BITMODE) {
            write8bits(value);
        } else {
            local val2 = value;
            write4bits(val2 >> 4);
            write4bits(val2);
        }
    } else {
        // we use SPI  ##########################################
        bitWrite(_bitString, _rs_pin, mode);  // set RS to mode
        spiSendOut();

        // we are not using RW with SPI so we are not even bothering
        // or 8BITMODE so we go straight to write4bits
        local val2 = value;
        write4bits(val2 >> 4);
        write4bits(val2);
    }
}

function LiquidCrystal::pulseEnable()
{
    if (_usingSpi == false) {
        _enable_pin.low();
        udelay(1);
        _enable_pin.high();
        udelay(1);    // enable pulse must be >450ns
        _enable_pin.low();
        udelay(100);   // commands need > 37us to settle
    } else {
        // we use SPI #############################################
        bitWrite(_bitString, _enable_pin, LOW);
        spiSendOut();
        udelays(1);
        bitWrite(_bitString, _enable_pin, HIGH);
        spiSendOut();
        udelay(1);    // enable pulse must be >450ns
        bitWrite(_bitString, _enable_pin, LOW);
        spiSendOut();
        udelay(40);   // commands need > 37us to settle
    }
}

function LiquidCrystal::write4bits(value)
{
    if (_usingSpi == false) {
        local ni;
        local val2 = value;
        for (ni = 0; ni < 4; ni++) {
            _data_pins[ni].output();
            if ((val2 >> ni) & 0x01) {
                _data_pins[ni].high();
            } else {
                _data_pins[ni].low();
            }
        }
    } else {
        // we use SPI ##############################################
        local si;
        local val2 = value;
        for (si = 4; si < 8; si++) {
           // we put the four bits in the _bit_string
           bitWrite(_bitString, si, ((val2 >> (si - 4)) & 0x01));
        }
        // and send it out
        spiSendOut();
    }
    pulseEnable();
}

function LiquidCrystal::write8bits(value)
{
    local vi;
    local val2 = value;
    for (vi = 0; vi < 8; vi++) {
        _data_pins[vi].output();
        if ((val2 >> vi) & 0x01) {
            _data_pins[vi].high();
        } else {
            _data_pins[vi].low();
        }
    }

    pulseEnable();
}

// SPI #############################
function LiquidCrystal::spiSendOut()
{
    // just in case you are using SPI for more then one device
    // set bitOrder, clockDivider and dataMode each time
    SPI.setClockDivider(_clockDivider);
    SPI.setBitOrder(_bitOrder);
    SPI.setDataMode(_dataMode);

    _latchPin.low();
    SPI.transfer(_bitString);
    _latchPin.high();
}

function LiquidCrystal::print(str)
{
    local loopc;
    local strLen = str.len();
    //print("len=" + strLen);
    local strBlob = blob(32);
    strBlob.seek(0, 'b');
    strBlob.writestr(str);
    strBlob.seek(0, 'b')
    for (loopc = 0; loopc < strLen; loopc++) {
        local ch = strBlob.readn('b');
        write(ch);
    }
}

