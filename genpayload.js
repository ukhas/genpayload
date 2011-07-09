// Set up blockUI and block the elements we don't want
$.blockUI.defaults.overlayCSS.opacity = 0.8;
$.blockUI.defaults.overlayCSS.cursor = 'default';
$.blockUI.defaults.baseZ = 500;
$.blockUI.defaults.message = null;
$('#radio,#telemetry,#dataformat,#documents').block();

var steps = [ "payload", "radio", "telemetry", "dataformat", "documents" ];
var current = 0;

var text = [
    "<p>Why are you back here? You only had to enter a NAME. Make sure you've entered a NAME.</p>",
    "<p>Great! Well done for entering that NAME.</p><p>However, further details are required to make your PAYLOAD DOCUMENT. You must enter a FREQUENCY in MEGAHERTZ and a MODE such as LSB or USB.</p><p>Good luck!</p>",
    "<p>You continue on your quest for a PAYLOAD DOCUMENT.</p><p>Further challenges await: you must enter TELEMETRY details now. The DEFAULTS may be to your liking, and if so you can SKIP through this section.</p>",
    "<p>Everything before now was the kiddy stuff. This is where we separate the wheat from the chaff. You must now enter the DATA FORMAT INFORMATION.</p><p>At first, enter a CALLSIGN which is how your PAYLOAD will identify itself in RADIO TELEMETRY. Once this is done, you must also enter the CHECKSUM ALGORITHM in use. Common choices here include CRC-16 and XOR.</p>",
    "<p>GAME OVER. You've entered all your information. There is nothing left to be done but reap the benefits of your hard labour in the form of these PAYLOAD DOCUMENTS. YOUR SCORE: 10 POINTS.</p>"
]

// Bind 'continue' links
$('.continue').click(function(e) {
    var index = steps.indexOf($(this).parent().attr('id'));
    $('#' + steps[index + 1] + ' > input:first').focus();
});

// Bind text entry to capitalise
$('input').keyup(function(e) {
    if(e.which >= 65 && e.which <= 90)
        this.value = this.value.toUpperCase();
});

// Bind focus events to shift the scroller into position
$('input').focus(function(e) {
    var section = $(this).parent().attr('id');
    var index = steps.indexOf(section);
    if(index != current) {
        $('#' + steps[current]).block();
        current = index;
        var new_top = 200 - $('#' + steps[current]).position().top;
        $('#scroller').animate({top: new_top + 'px'}, 800, 'linear');
        $('#' + steps[current]).unblock();
        $('#text').html(text[current]);
    }
});

