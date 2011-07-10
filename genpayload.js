// Set up blockUI and block the elements we don't want
$.blockUI.defaults.overlayCSS.opacity = 0.8;
$.blockUI.defaults.overlayCSS.cursor = 'default';
$.blockUI.defaults.baseZ = 500;
$.blockUI.defaults.message = null;
$('#flight,#radio,#telemetry,#dataformat,#documents').block();

// Bind datetime selectors
$('#window_start,#window_end').datepicker({dateFormat: 'yy-mm-dd'});
$('#launch_date').datetimepicker({dateFormat: 'yy-mm-dd'});

var steps = [   "payload", "flight", "radio", "telemetry",
                "dataformat", "documents" ];
var current = 0;

var text = [
    "<p>Why are you back here? You only had to enter a NAME. Make sure you've entered a NAME.</p>",
    "<p>Okay, now for some FLIGHT DETAILS. You have to reveal the LAUNCH LOCATION and the PROJECT NAME first.</p><p>Once past that first hurdle, you will have to input the LAUNCH WINDOW and the ESTIMATED LAUNCH TIME for this flight. Finally, input the LOCAL TIMEZONE for the flight.</p><p>Now, onwards to greater challenges!</p>",
    "<p>Great! Well done for entering the FLIGHT DETAILS.</p><p>However, further details are required to make your PAYLOAD DOCUMENT. You must enter a FREQUENCY in MEGAHERTZ and a MODE such as LSB or USB.</p><p>Good luck!</p>",
    "<p>You continue on your quest for a PAYLOAD DOCUMENT.</p><p>Further challenges await: you must enter TELEMETRY details now. The DEFAULTS may be to your liking, and if so you can SKIP through this section.</p>",
    "<p>Everything before now was the kiddy stuff. This is where we separate the wheat from the chaff. You must now enter the DATA FORMAT INFORMATION.</p><p>First things first. Enter the CALLSIGN, the identifier the PAYLOAD uses in the RADIO TELEMETRY STRINGS.</p><p>The second step, and toughest trial you will face, is to select the FIELDs for your SENTENCE. This arduous challenge is undertaken by DRAG AND DROPing FIELDs from the list on the right into the FIELD RECEPTACLE on the left. You can also SORT the FIELDs by DRAGGING them inside the FIELD RECEPTACLE. You must then enter the FIELD CONFIGURATION INFORMATION into each FIELD.</p><p>Typically, the FIELD CONFIGURATION INFORMATION is only a FIELD NAME. On rare occasion it may be required of you to enter a FIELD FORMAT. If this happens to you, do not fear! Simply choose from `DD.DDDD' or `DDMM.MM', and good luck.</p><p>Finally, input the CHECKSUM ALGORITHM. Common choices include CRC-16 and XOR.</p>",
    "<p>GAME OVER. You've entered all your information. There is nothing left to be done but reap the benefits of your hard labour in the form of these PAYLOAD DOCUMENTS. YOUR SCORE: 10 POINTS.</p>"
]

// Bind 'continue' links
$('.continue').click(function(e) {
    var index = steps.indexOf($(this).parent().attr('id'));
    $('#' + steps[index + 1] + ' > input:first').focus();
    return false;
});

// Bind 'back' links
$('.back').click(function(e) {
    var index = steps.indexOf($(this).parent().attr('id'));
    $('#' + steps[index - 1] + ' > input:first').focus();
    return false;
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
        $('#text').html(text[current]);
        var header_height = $('#top-bar').height();
        var new_top = header_height - $('#' + steps[current]).position().top;
        $('#scroller').animate({top: new_top + 'px'}, 800, 'linear');
        $('#' + steps[current]).unblock();
        // set the correct max_height to make sure overflow works okay
        var max_height = $(window).height() - $('#top-bar').height();
        max_height -= 70;
        $('#' + steps[current]).css('max-height', max_height + 'px');
    }
});

// Make fields draggable and such
$('.field').draggable({
    helper: "clone",
    appendTo: "body"
});

// Generate the sentence-field items
var sentence_field_count = 0;
function generate_sentence_field(type) {
    var container = $('<div class="sentence-field"></div>');
    var body = '<strong>'+type+'</strong><br />';
    body += '<label for="sentence-field-' + sentence_field_count + '">';
    body += 'FIELD NAME&gt;</label>';
    body += '<input type="text" size="12" id="sentence-field-';
    body += sentence_field_count + '"';
    if(type == "TIME") {
        body += ' value="time"';
    }
    body += ' required><br />';
    container.append(body);
    if(type == "COORDINATE") {
        body = '<label for="sentence-field-';
        body += sentence_field_count + '-format">FORMAT&gt;';
        body += '</label><input type="text" size="12" id="';
        body += 'sentence-field-' + sentence_field_count;
        body += '-format" value="dd.dddd" required><br />';
        container.append(body);
    }
    sentence_field_count++;
    return container;
};

// Make the sentence box droppable and sortable
$('#sentence').droppable({
    accept: ":not(.ui-sortable-helper)",
    drop: function(event, ui) {
        generate_sentence_field(ui.draggable.text()).appendTo(this);
    }
}).sortable({
    items: "div"
});

// Make the fields list droppable to 'remove'
$('#fields').droppable({
    drop: function(event, ui) {
        ui.draggable.remove();
    }
});
