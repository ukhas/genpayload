// Set up blockUI and block the elements we don't want
$.blockUI.defaults.applyPlatformOpacityRules = false;
$.blockUI.defaults.overlayCSS.opacity = 0.8;
$.blockUI.defaults.overlayCSS.cursor = 'default';
$.blockUI.defaults.baseZ = 500;
$.blockUI.defaults.message = null;
$('#flight,#radio,#telemetry,#dataformat,#documents').block();

// Bind datetime selectors
$('#window-start').datepicker({
    dateFormat: 'yy-mm-dd',
    onClose: function(date_text, inst) {
        $('#window-start').focus();
    }
});
$('#window-end').datepicker({
    dateFormat: 'yy-mm-dd',
    onClose: function(date_text, inst) {
        $('#window-end').focus();
    }
});
$('#launch-date').datetimepicker({
    dateFormat: 'yy-mm-dd',
    onClose: function(date_text, inst) {
        $('#launch-date').focus();
    }
});

var steps = [   "payload", "flight", "radio", "telemetry",
                "dataformat", "documents" ];
var current = 0;

var text = [
    "<p>Why are you back here? You only had to enter a NAME. Make sure you've entered a NAME.</p>",
    "<p>Okay, now for some FLIGHT DETAILS. You have to reveal the LAUNCH LOCATION and the PROJECT NAME first.</p><p>Once past that first hurdle, you will have to input the LAUNCH WINDOW and the ESTIMATED LAUNCH TIME for this flight. These are both in the LOCAL TIME. Finally, input the LOCAL TIMEZONE for the flight.</p><p>Now, onwards to greater challenges!</p>",
    "<p>Great! Well done for entering the FLIGHT DETAILS.</p><p>However, further details are required to make your PAYLOAD DOCUMENT. You must enter a FREQUENCY in MEGAHERTZ and a MODE such as LSB or USB.</p><p>Good luck!</p>",
    "<p>You continue on your quest for a PAYLOAD DOCUMENT.</p><p>Further challenges await: you must enter TELEMETRY details now. The DEFAULTS may be to your liking, and if so you can SKIP through this section.</p>",
    "<p>Everything before now was the kiddy stuff. This is where we separate the wheat from the chaff. You must now enter the DATA FORMAT INFORMATION.</p><p>First things first. Enter the CALLSIGN, the identifier the PAYLOAD uses in the RADIO TELEMETRY STRINGS.</p><p>The second step, and toughest trial you will face, is to select the FIELDs for your SENTENCE. This arduous challenge is undertaken by DRAG AND DROPing FIELDs from the list on the right into the FIELD RECEPTACLE on the left. FIELDs on the left may be deleted by DRAG AND DROPing them back to the FIELD LIST on the right. You can also SORT the FIELDs by DRAGGING them inside the FIELD RECEPTACLE. You must then enter the FIELD CONFIGURATION INFORMATION into each FIELD.</p><p>Typically, the FIELD CONFIGURATION INFORMATION is only a FIELD NAME. On rare occasion it may be required of you to enter a FIELD FORMAT. If this happens to you, do not fear! Simply choose from `DD.DDDD' or `DDMM.MM', and good luck.</p><p>Finally, input the CHECKSUM ALGORITHM. Common choices include CRC-16 and XOR.</p>",
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

// Bind focus events to shift the scroller into position
$('input').focus(function(e) {
    var section = $(this).parent().attr('id');
    var index = steps.indexOf(section);
    if(index != current) {
        $('#' + steps[current]).block();
        $('#' + steps[current]).scrollTop(0);
        $('#' + steps[current]).css('overflow-y', 'hidden');
        current = index;
        $('#text').html(text[current]);
        var header_height = $('#top-bar').height();
        var new_top = header_height - $('#' + steps[current]).position().top;
        $('#scroller').animate({top: new_top + 'px'}, 800, 'linear');
        $('#' + steps[current]).unblock();
        $('#' + steps[current]).css('overflow-y', 'auto');
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
    var name = "";
    if(type == "LATITUDE") {
        type = "COORDINATE";
        name = "latitude";
    } else if(type == "LONGITUDE") {
        type = "COORDINATE";
        name = "longitude";
    } else if(type == "ALTITUDE") {
        type = "INTEGER";
        name = "altitude";
    } else if(type == "TEMPERATURE") {
        type = "FLOAT";
        name = "temperature";
    }
    var container = $('<div class="sentence-field"></div>');
    var body = '<strong>'+type+'</strong><br />';
    body += '<label for="sentence-field-' + sentence_field_count + '">';
    body += 'FIELD NAME&gt;</label>';
    body += '<input type="text" size="12" id="sentence-field-';
    body += sentence_field_count + '"';
    if(type == "TIME") {
        body += ' value="time"';
    } else if(name != "") {
        body += ' value="' + name + '"';
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

function set_sentence_field_tabindicies() {
    var tabindex = 20;
    $('#sentence input').each(function(index, element) {
        $(element).attr('tabindex', tabindex);
        tabindex++;
    });
}

// Make the sentence box droppable and sortable
$('#sentence').droppable({
    accept: ":not(.ui-sortable-helper)",
    drop: function(event, ui) {
        generate_sentence_field(ui.draggable.text()).appendTo(this);
        set_sentence_field_tabindicies();
        $(this).children('.sentence-field:last').children('input:first').focus();
    }
}).sortable({
    items: "div"
});

// Give some default fields
generate_sentence_field('INTEGER').appendTo($('#sentence'));
generate_sentence_field('TIME').appendTo($('#sentence'));
generate_sentence_field('COORDINATE').appendTo($('#sentence'));
generate_sentence_field('COORDINATE').appendTo($('#sentence'));
generate_sentence_field('ALTITUDE').appendTo($('#sentence'));
$('.sentence-field:eq(0)').children('input').val('count');
$('.sentence-field:eq(1)').children('input').val('time');
$('.sentence-field:eq(2)').children('input:eq(0)').val('latitude');
$('.sentence-field:eq(3)').children('input:eq(0)').val('longitude');
set_sentence_field_tabindicies();

// Make the fields list droppable to 'remove'
$('#fields').droppable({
    drop: function(event, ui) {
        ui.draggable.remove();
    }
});

// the fun part
function make_json() {
    var field_list = [];
    $('#sentence > div.sentence-field').each(function(index, element) {
        var sensor = $(element).children('strong').text().toLowerCase();
        var name = $(element).children('input:first').val();
        switch(sensor) {
            case "time":
                sensor = "stdtelem.time";
                break;
            case "coordinate":
                sensor = "stdtelem.coordinate";
                break;
            case "integer":
                sensor = "base.ascii_int";
                break;
            case "float":
                sensor = "base.ascii_float";
                break;
            case "string":
                sensor = "base.string";
                break;
        }
        var field = { name: name, sensor: sensor }
        if(sensor == "stdtelem.coordinate") {
            field.format = $(element).children('input:last').val();
        }
        field_list.push(field);
    });
    var checksum = $('#checksum').val().toLowerCase();
    if(checksum == "crc-16")
        checksum = "crc16-ccitt";
    var payload =  {
        radio: {
            frequency: $('#frequency').val(),
            mode: $('#mode').val()
        },
        telemetry: {
            modulation: $('#modulation').val().toLowerCase(),
            shift: $('#shift').val(),
            encoding: $('#encoding').val().toLowerCase(),
            baud: $('#baud').val(),
            parity: $('#parity').val().toLowerCase(),
            stop: $('#stop').val()
        },
        sentence: {
            protocol: "UKHAS",
            checksum: checksum,
            payload: $('#callsign').val(),
            fields: field_list
        }
    };
    var flight_doc = {
        type: "flight",
        name: $('#name').val(),
        start: new Date($('#window-start').val()).getTime() / 1000,
        end: new Date($('#window-end').val()).getTime() / 1000,
        launch: {
            time: new Date($('#launch-date').val()).getTime() / 1000,
            timezone: $('#timezone').val()
        },
        metadata: {
            location: $('#location').val(),
            project: $('#project').val()
        },
        payloads: {}
    };
    flight_doc.payloads[$('#callsign').val()] = payload;
    return flight_doc;
}

function make_xml(root) {
    root.empty();
    root.append("<transmission></transmission>");
    var transmission = root.children("transmission");
    transmission.append("<frequency>"+$('#frequency').val()+".00</frequency>");
    transmission.append("<mode>"+$('#mode').val()+"</mode>");
    transmission.append("<timings>continuous</timings>");
    transmission.append("<txtype><rtty></rtty></txtype>");
    var rtty = transmission.children("txtype").children("rtty");
    rtty.append("<shift>"+$('#shift').val()+"</shift>");
    rtty.append("<coding>"+$('#encoding').val().toLowerCase()+"</coding>");
    rtty.append("<baud>"+$('#baud').val()+"</baud>");
    rtty.append("<parity>"+$('#parity').val().toLowerCase()+"</parity>");
    rtty.append("<stop>"+$('#stop').val()+"</stop>");
    transmission.append("<sentence></sentence>");
    var sentence = transmission.children("sentence");
    sentence.append("<sentence_delimiter>$$</sentence_delimiter>");
    sentence.append("<string_limit>999</string_limit>");
    sentence.append("<field_delimiter>,</field_delimiter>");
    sentence.append("<fields>"+$('#sentence > div').length+"</fields>");
    sentence.append("<callsign>"+$('#callsign').val()+"</callsign>");
    var callsign_field = "<field><seq>1</seq><dbfield>callsign</dbfield>";
    callsign_field += "<minsize>"+$('#callsign').val().length+"</minsize>";
    callsign_field += "<maxsize>"+$('#callsign').val().length+"</maxsize>";
    callsign_field += "<datatype>char</datatype></field>";
    sentence.append(callsign_field);
    $('#sentence > div.sentence-field').each(function(index, element) {
        var type = $(element).children('strong').text().toLowerCase();
        var name = $(element).children('input:first').val();
        var format = null;
        if(type == "coordinate") {
            format = $(element).children('input:last').val();
        }
        switch(type) {
            case "coordinate":
                type = "decimal"
                break;
            case "float":
                type = "decimal";
                break;
            case "string":
                type = "char";
                break;
        }
        var field = $("<field></field>");
        field.append("<seq>"+(index + 2)+"</seq>");
        field.append("<dbfield>"+name+"</dbfield>");
        field.append("<minsize>0</minsize>");
        field.append("<maxsize>99</maxsize>");
        field.append("<datatype>"+type+"</datatype>");
        if(format != null) {
            field.append("<format>"+format+"</format>");
        }
        sentence.append(field);
    });
    return root;
}

$('#json-flight-doc,#xml-flight-doc').focus(function(e) {
    var flight_doc = JSON.stringify(make_json());
    $('#json-flight-doc').val(flight_doc);
    flight_doc = make_xml($('#xml-root')).html();
    $('#xml-flight-doc').val(flight_doc);
});

