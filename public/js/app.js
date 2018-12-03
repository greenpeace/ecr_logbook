
function init(element) {
  if(typeof element == "undefined" || element == "#" || element == "") element = "#main"
  section = element.split(/\//)[0]
  card = element.split(/\//)[1]
  $("nav small.title").text($("#rooms > li > a[data-href="+section.substr(1)+"]").text())
  $("section").hide();
  $(section).show();
  $("main").show();
  M.updateTextFields();
  if(typeof card != "undefined") {
    console.log(card)
    $(document).scrollTop( $(".card."+card).offset().top );
  }
}

$("a.navlink").on("click",function(){
  init($(this).attr("href"))
  if($(this).closest("#nav-mobile").length > 0) $("#nav-mobile").sidenav("close");
})

$("form#daylog .input-field.dev select").on("change",function(){
  $(".input-field.devhide").slideUp();
  $(".input-field.devhide."+$(this).find("option:selected").val()).slideDown();
})

$("form#daylog .input-field input[type=number]").on("blur",function(){
  checkNumber(this);
  checkSystem($(this).closest(".card"));
})

$("form#daylog .input-field input[type=checkbox]").on("change",function(){
  checkSwitch(this);
  checkSystem($(this).closest(".card"));
})

$("form#daylog .input-field select").on("change",function(){
  checkSelect(this);
  checkSystem($(this).closest(".card"));
})

function checkSystem(card) {
  total = card.find("input:visible[type=number], select").length;
  valid = card.find("input.valid:visible[type=number]").length + card.find("ul.select-dropdown li.selected").not("ul.select-dropdown li.disabled").length;
  if (valid < total) {
    card.find(".card-valid i").fadeOut();
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .yes").hide();
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .maybe").show();
  } else {
    card.find(".card-valid i").fadeIn();
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .yes").show();
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .maybe").hide();
  }
  checkRoom(card.closest("section"));
}

function checkRoom(room) {
  total = room.find(".card").length;
  valid = room.find(".card[data-valid=true]").length;
  if (valid < total) {
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .yes").hide();
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .maybe").show();
  } else {
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .yes").show();
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .maybe").hide();
  }
}

function checkNumber(input) {
  $(input).prevAll("i.prefix").hide()
  if (input.validity.valid === true) {
    $(input).prevAll("i.prefix.yes").show()
    $(input).removeClass("invalid").addClass("valid")
  } else if (input.validity.valueMissing === true && input.validity.badInput === false) {
    $(input).prevAll("i.prefix.maybe").show()
    $(input).removeClass("invalid").removeClass("valid")
  } else {
    $(input).prevAll("i.prefix.no").show()
    $(input).removeClass("valid").addClass("invalid")
  }
}

function checkSwitch(input) {
  $(input).closest(".clearfix").prevAll("i.prefix").hide()
  if ($(input).prop("checked")) {
    $(input).closest(".clearfix").prevAll("i.prefix.yes").show()
  } else {
    $(input).closest(".clearfix").prevAll("i.prefix.maybe").show()
  }
}

function checkSelect(input) {
  $(input).closest(".select-wrapper").prevAll("i.prefix").hide()
  if ($(input).find("option:selected").prop("disabled")) {
    $(input).closest(".select-wrapper").prevAll("i.prefix.maybe").show()
  } else {
    $(input).closest(".select-wrapper").prevAll("i.prefix.yes").show()
  }
}

function checkInputs() {
  $.each($("form#daylog .input-field select"),function(i,e){ checkSelect(e); })
  $.each($("form#daylog .input-field input[type=number]"),function(i,e){ checkNumber(e); })
  $.each($("form#daylog .input-field input[type=checkbox]"),function(i,e){ checkSwitch(e); })
}

function setLocal(key,value) {
  localStorage[key] = String(value);
}


