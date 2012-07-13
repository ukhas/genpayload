/*
 Internet Timestamp Generator
 Copyright (c) 2009 Sebastiaan Deckers
 License: GNU General Public License version 3 or later
*/

Date.prototype.toRFC3339 = function () {
 var pad = function (amount, width) {
  var padding = "";
  while (padding.length < width - 1 && amount < Math.pow(10, width - padding.length - 1))
   padding += "0";
  return padding + amount.toString();
 }
 var offset = this.getTimezoneOffset();
 return pad(this.getFullYear(), 4)
   + "-" + pad(this.getMonth() + 1, 2)
   + "-" + pad(this.getDate(), 2)
   + "T" + pad(this.getHours(), 2)
   + ":" + pad(this.getMinutes(), 2)
   + ":" + pad(this.getSeconds(), 2)
   + "." + pad(this.getMilliseconds(), 3)
   + (offset > 0 ? "-" : "+")
   + pad(Math.floor(Math.abs(offset) / 60), 2)
   + ":" + pad(Math.abs(offset) % 60, 2);
}