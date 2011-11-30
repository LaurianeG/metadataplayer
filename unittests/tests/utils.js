function test_utils() {
  module("Utility function tests");
  
  test("test a function to preserve the scope of a method in a callback", function() {
    var obj = { a : 2};
    obj.b = function(e, f) { 
      equal(this.a, 2, "the scope is preserved");
      equal(e, 1, "arg 1 passed correctly");
      equal(f, 2, "arg 2 passed correctly");
    };
    
    (IriSP.wrap(obj, obj.b))(1, 2);
  
  });
  
  test("test function to convert a ratio to a percentage", function() {
    var time = 2;
    var total = 3;
    
    equal(IriSP.timeToPourcent(2, 3), 66, "the function returns the correct result");    
    
    var total = -total;    
    
    equal(IriSP.timeToPourcent(2, 3), 66, "the function is immune to negative numbers");            
  });
  
  test("test padding function", function() {
    equal(IriSP.padWithZeros(3), "03", "function works correctly");
  });
  
  test("test function to convert from seconds to a time", function() {
    var h = 13, m = 7, s = 41;
    var t = 13 * 3600 + 7* 60 + 41;
    
    var r = IriSP.secondsToTime(t);
    ok(r.hours === h && r.minutes === m && r.seconds === s, "the converted time is correct");
    
    t = -t;
    var r = IriSP.secondsToTime(t);
    ok(r.hours === h && r.minutes === m && r.seconds === s, "the function is immune to negative numbers.");
    equal(IriSP.secondsToTime(t), "13:07:41");
  });
  
  test("test function to format a tweet", function() {
    var input = "@handle @bundle #hashtag http://t.co/11111";
    var output = "<a href='http://twitter.com/handle'>@handle</a> <a href='http://twitter.com/bundle'>@bundle</a> <a href='http://twitter.com/search?q=%23hashtag'>#hashtag</a> <a href='http://t.co/11111'>http://t.co/11111</a>";
    equal(IriSP.formatTweet(input), output, "the correct output is given");
  });

  test("test function to convert decimal color to hexadecimal", function() {
    equal(IriSP.DEC_HEXA_COLOR(125), "7D", "first test passes");
    equal(IriSP.DEC_HEXA_COLOR(24345), "5F19", "second test passes");

  });
}
