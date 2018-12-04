
function init(element) {
  if(typeof element == "undefined" || element == "#" || element == "") element = "#main"
  //console.log(element)
  section = element.split(/\//)[0]
  card = element.split(/\//)[1]
  $("nav small.title").text($("#rooms > li > a[data-href="+section.substr(1)+"]").text())
  $("section").hide();
  $(section).show();
  $("main").show();
  M.updateTextFields();
  if(typeof card != "undefined") {
    $(document).scrollTop( $(".card."+card).offset().top - 56 );
  }
  if (element.split(/\//).length == 3 ) {
    $(element.split(/\//).join("_")).focus();
  } 
}

$(".foot-arrows a").on("click",function(){
  init($(this).attr("href"));
})

$("body").on("click","a.navlink",function(){
  init($(this).attr("href"))
  if($(this).closest("#nav-mobile").length > 0) $("#nav-mobile").sidenav("close");
})

$("form#daylog .input-field.dev select").on("change",function(){
  $(this).closest(".dev").nextAll(".input-field.devhide").slideUp();
  $(this).closest(".dev").nextAll(".input-field.devhide input").prop("required", false);
  $(this).closest(".dev").nextAll(".input-field.devhide."+$(this).find("option:selected").val()).slideDown();
  $(this).closest(".dev").nextAll(".input-field.devhide."+$(this).find("option:selected").val()).find("input").prop("required", true);
})


// Validations

$("form#daylog button.submit").off("click tap").on("click tap",function(){
  if (validateForm()) {
    $("form#daylog").submit();
  } else {
    $(".errors").slideDown();
  }
})

function validateForm(){
  $(".errors").slideUp();
  $(".errors .content").html("");
  err = 0
  $.each($("form#daylog input").not(".valid"),function(i,e){
    if (typeof $(e).attr("name") !== "undefined" && $(e).attr("type") !== "hidden" && $(e).attr("type") !== "checkbox") {
      err ++;
      addr = $(e).attr("name").split("_");
      if (addr.length == 1 ) {
        href = "#submit";
        txt = "<b>"+$(e).next("label").text() + "</b> (just above)";
      } else {
        href = "#"+ addr.join("/");
        txt = "<b>"+$(e).next("label").text() + "</b> (" + $(e).closest("section").find("h5").text() + " / " + $(e).closest(".card").find(".card-title").text() + ")";
      }
      $(".errors .card .content").append("<li><a class='white-text navlink' href='"+href+"'>"+txt+"</a></li>")
    }
  })
  return err == 0
}

$("form#daylog .input-field input[type=number], input.ex").on("blur",function(){
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

function checkRoom(room) {
  total = room.find(".card").length;
  valid = room.find(".card[data-valid=true]").length;
  //console.log(room.attr("id")+": "+valid+" / "+total)
  if (valid < total) {
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .yes").hide();
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .maybe").show();
  } else {
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .yes").show();
    $("#nav-mobile a.collapsible-header[data-href="+room.attr("id")+"] .maybe").hide();
  }
}

function checkSystem(card) {
  total = card.find("input:required[type=number], select").length;
  valid = card.find("input.valid:required[type=number]").length + card.find("ul.select-dropdown li.selected").not("ul.select-dropdown li.disabled").length;
  //console.log(card.attr("id")+": "+valid+" / "+total)
  if (valid < total) {
    card.find(".card-valid i").fadeOut();
    card.attr("data-valid","false")
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .yes").hide();
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .maybe").show();
  } else {
    card.find(".card-valid i").fadeIn();
    card.attr("data-valid","true")
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .yes").show();
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .maybe").hide();
  }
  checkRoom(card.closest("section"));
}

function checkNumber(input) {
  $(input).prevAll("i.prefix").hide()
  if (input.validity.valid === true) {
    $(input).prevAll("i.prefix.yes").show()
    $(input).removeClass("invalid").addClass("valid")
    setLocal($(input).attr("name"),$(input).val())
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
    $(input).closest(".clearfix").prevAll("checkhide").prop("disabled",true)
    setLocal($(input).attr("name"),"on");
  } else {
    $(input).closest(".clearfix").prevAll("i.prefix.maybe").show()
    $(input).closest(".clearfix").prevAll("checkhide").prop("disabled",false)
    setLocal($(input).attr("name"),"off");
  }
}

function checkSelect(input) {
  $(input).closest(".select-wrapper").prevAll("i.prefix").hide()
  if ($(input).find("option:selected").prop("disabled")) {
    $(input).closest(".select-wrapper").prevAll("i.prefix.maybe").show()
  } else {
    $(input).closest(".select-wrapper").prevAll("i.prefix.yes").show()
    setLocal($(input).attr("name"),$(input).val())
  }
}

function checkInputs() {
  $.each($("form#daylog .input-field select"),function(i,e){ checkSelect(e); })
  $.each($("form#daylog .input-field input[type=number], input.ex"),function(i,e){ checkNumber(e); })
  $.each($("form#daylog .input-field input[type=checkbox]"),function(i,e){ checkSwitch(e); })
  $.each($("form#daylog .card"),function(i,e){ checkSystem($(e)); })
  $.each($("form#daylog section.room"),function(i,e){ checkRoom($(e)); })
}

function setLocal(key,value) {
  localStorage[key] = String(value);
}


// debug

function prefill() {
  $.get("/localStorage",function(data){
    data = data.replace(/^\s*"/,"").replace(/"\s*$/,"").split("&")
    $.each(data,function(i,e){
      d = e.split("=");
      if (d[1] == "on") {
        $("input[name="+d[0]+"]").prop("checked",true)
      } else if (d[0].match(/_running/)) {
        $("select[name="+d[0]+"] option[value="+d[1]+"]").prop("selected",true)
        $("select[name="+d[0]+"]").formSelect();
        if ($("select[name="+d[0]+"]").closest(".input-field").hasClass("dev")) {
          console.log($("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide."+$("select[name="+d[0]+"]").find("option:selected").val()));
          $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide").slideUp();
          $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide input").prop("required", false);
          $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide."+$("select[name="+d[0]+"]").find("option:selected").val()).slideDown();
          $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide."+$("select[name="+d[0]+"]").find("option:selected").val()).find("input").prop("required", true);
        }
      } else {
        $("input[name="+d[0]+"]").val(d[1])
      }
    })
    M.updateTextFields();
    checkInputs();
  })
}
