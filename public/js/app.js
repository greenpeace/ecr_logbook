var lubeTokens = []

function init(element) {
  element = element.replace(/^\//,"")
  if(typeof element == "undefined" || element == "#" || element == "") element = "#main"
  //console.log(element)
  section = element.split(/\//)[0]
  card = element.split(/\//)[1]
  $("nav small.title").text($("#rooms > li > a[data-href="+section.substr(1)+"]").text())
  $("#daylog section").hide();
  $(section).show();
  $("main").show();
  M.updateTextFields();
  if(typeof card != "undefined") {
    $(document).scrollTop( $(".card."+card).offset().top - 56 );
  } else {
    $(document).scrollTop(0);
  }
  if (element.split(/\//).length == 3 ) {
    $(element.split(/\//).join("_")).focus();
  } 
}

$(".card.system .card-content .clearfix").on("click",function(){
  check = $(this).closest(".card").find(".switch.sys input")
  if (!check.prop("checked")) {
    check.prop("checked",true);
    toggleSystem(check)
  }
})

$(".switch.sys input").on("change",function(){
  toggleSystem($(this))
})

$("form#daylog input[type=range]").on("change",function(){
  $(".range-value[data-source="+$(this).attr("id")+"]").text($(this).val())
})

function toggleSystem(check) {
  me = check.closest(".card-content").next(".card-action");
  card = check.closest(".card");
  if (check.prop("checked")) {
    me.find("input, select").prop("required", true);
    if(me.find("select.ex").length > 0) {
      $.each(me.find("select.ex").find("option").not(":disabled,:selected"),function(i,e){
        me.find("select.ex").closest(".dev").nextAll(".input-field.devhide."+$(e).val()).find("input").prop("required",false)
      })
    }
    card.find(".card-valid i").removeClass("grey-text").addClass("teal-text");
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .yes").removeClass("grey-text").addClass("teal-text");
    me.slideDown(function(){
      card = check.closest(".card");
      $.each(me.find(".input-field select"),function(i,e){ checkSelect(e); })
      $.each(me.find(".input-field input[type=number], input.ex"),function(i,e){ checkNumber(e); })
      $.each(me.find(".input-field input[type=checkbox]"),function(i,e){ checkSwitch(e); })
      $.each(me.find(".input-field input[type=radio]"),function(i,e){ checkRadio(e); })
      $.each(me.find(".input-field input[type=range]"),function(i,e){ checkRange(e); })
      checkSystem(card);
    });
  } else {
    me.find("input, select").prop("required", false);
    card.find(".card-valid i").addClass("grey-text").removeClass("teal-text");
    $("#nav-mobile a.navlink[data-href="+card.attr("id")+"] .yes").addClass("grey-text").removeClass("teal-text");
    me.slideUp(function(){
      card = check.closest(".card");
      $.each(me.find(".input-field select"),function(i,e){ checkSelect(e); })
      $.each(me.find(".input-field input[type=number], input.ex"),function(i,e){ checkNumber(e); })
      $.each(me.find(".input-field input[type=checkbox]"),function(i,e){ checkSwitch(e); })
      $.each(me.find(".input-field input[type=radio]"),function(i,e){ checkRadio(e); })
      $.each(me.find(".input-field input[type=range]"),function(i,e){ checkRange(e); })
      checkSystem(card);
    });
  }
}

$("a.lube-add").on("click",function(){
  $.get("/newlube?room="+$(this).closest("section").attr("id"),function(data){
    $("#modal .modal-content").html(data);
    $("#modal").modal("open")
  })
})

$("form#daylog").on("click","a.lube-del",function(){
  token = $(this).attr("id").replace("lube-del-","");
  delLube(token);
})

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
  $.each($(this).closest(".dev").nextAll(".input-field.devhide."+$(this).find("option:selected").val()).find("input"),function(i,e){ checkNumber(e); })
})


// Validations

$("form#daylog button.submit").off("click tap").on("click tap",function(){
  if (validateForm()) {
    localStorage.clear();
    $("form#daylog").submit();
  } else {
    $(".errors").slideDown();
    $("#anyway").show();
  }
})

$("form#daylog button#anyway").off("click tap").on("click tap",function(){
  $("form#daylog").attr("novalidate","novalidate");
  localStorage.clear();
  $("form#daylog").submit();
})

function validateForm(){
  $(".errors").slideUp();
  $("#anyway").hide();
  $(".errors .content").html("");
  err = 0
  $.each($("form#daylog input").not(".valid"),function(i,e){
    if (typeof $(e).attr("name") !== "undefined" && $(e).attr("type") !== "hidden" && $(e).attr("type") !== "checkbox") {
      err ++;
      addr = $(e).attr("name").split("_");
      if (addr.length == 1 ) {
        href = "#submit";
        txt = "<b>"+$(e).next("label").text() + "</b> (just above)";
      } else if ($(e).attr("type") == "radio") {
        console.log(addr)
        href = "#"+ addr.join("/");
        txt = "<b>"+$(e).closest(".clearfix").find("label.fix").text() + "</b> (" + $(e).closest("section").find("h5").text() + " / " + $(e).closest(".card").find(".card-title").text() + ")";
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
  checkNumber(this,true);
  checkSystem($(this).closest(".card"));
})

$("form#daylog .input-field input[type=checkbox]").on("change",function(){
  checkSwitch(this,true);
  checkSystem($(this).closest(".card"));
})

$("form#daylog .input-field input[type=radio]").on("change",function(){
  checkRadio(this,true);
  checkSystem($(this).closest(".card"));
})

$("form#daylog .input-field input[type=range]").on("change",function(){
  checkRange(this,true);
  checkSystem($(this).closest(".card"));
})

$("form#daylog .input-field select").on("change",function(){
  checkSelect(this,true);
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
  total = card.find("input:required[type=number], select:required").length;
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

function checkNumber(input,force) {
  $(input).prevAll("i.prefix").hide()
  if (input.validity.valid === true) {
    $(input).prevAll("i.prefix.yes").show()
    $(input).removeClass("invalid").addClass("valid")
    setLocal($(input).attr("name"),$(input).val(),force)
  } else if (input.validity.valueMissing === true && input.validity.badInput === false) {
    $(input).prevAll("i.prefix.maybe").show()
    $(input).removeClass("invalid").removeClass("valid")
  } else {
    $(input).prevAll("i.prefix.no").show()
    $(input).removeClass("valid").addClass("invalid")
  }
}

function checkSwitch(input,force) {
  $(input).closest(".clearfix").prevAll("i.prefix").hide()
  if ($(input).prop("checked")) {
    $(input).closest(".clearfix").prevAll("i.prefix.yes").show()
    $(input).closest(".clearfix").prevAll("checkhide").prop("disabled",true)
    setLocal($(input).attr("name"),"on",force);
  } else {
    $(input).closest(".clearfix").prevAll("i.prefix.maybe").show()
    $(input).closest(".clearfix").prevAll("checkhide").prop("disabled",false)
    setLocal($(input).attr("name"),(force ? "off" : ""),force);
  }
}

function checkRadio(input,force) {
  $(input).closest(".clearfix").prevAll("i.prefix").hide()
  if ($("input[name="+$(input).attr("name")+"]:checked").length > 0) {
    $(input).closest(".clearfix").prevAll("i.prefix.yes").show();
    $("input[name="+$(input).attr("name")+"]").addClass("valid");
    setLocal($(input).attr("name"),$(input).val(),force);
  } else {
    $(input).closest(".clearfix").prevAll("i.prefix.maybe").show()
    $("input[name="+$(input).attr("name")+"]:first").removeClass("valid");
  }
  $("input[name="+$(input).attr("name")+"]").not(":visible").addClass("valid");
}

function checkRange(input,force) {
  $(input).closest(".range").prevAll("i.prefix").hide()
  $(".range-value[data-source="+$(input).attr("id")+"]").text($(input).val())
  if ($(input).val() > 0) {
    $(input).closest(".range").prevAll("i.prefix.yes").show()
    setLocal($(input).attr("name"),$(input).val(),force);
  } else {
    $(input).closest(".range").prevAll("i.prefix.maybe").show()
    setLocal($(input).attr("name"),(force ? 0 : ""),force);
  }
}

function checkSelect(input,force) {
  $(input).closest(".select-wrapper").prevAll("i.prefix").hide()
  if ($(input).find("option:selected").prop("disabled")) {
    $(input).closest(".select-wrapper").prevAll("i.prefix.maybe").show()
  } else {
    $(input).closest(".select-wrapper").prevAll("i.prefix.yes").show()
    setLocal($(input).attr("name"),$(input).val(),force);
  }
}

function checkInputs() {
  $.each($("form#daylog .input-field select"),function(i,e){ checkSelect(e,false); })
  $.each($("form#daylog .input-field input[type=number], input.ex"),function(i,e){ checkNumber(e,false); })
  $.each($("form#daylog .input-field input[type=checkbox]"),function(i,e){ checkSwitch(e,false); })
  $.each($("form#daylog .input-field input[type=radio]"),function(i,e){ checkRadio(e,false); })
  $.each($("form#daylog .input-field input[type=range]"),function(i,e){ checkRange(e,false); })
  $.each($("form#daylog .card"),function(i,e){ checkSystem($(e)); })
  //$.each($("form#daylog section.room"),function(i,e){ checkRoom($(e)); })
  //$.each($(".switch.sys input[type=checkbox]:checked"),function(i,e){ toggleSystem($(e))})
}

function setLocal(key,value,force) {
  if ((value !== null && String(value).length > 0) || force) {
    localStorage[key] = String(value);
  }
}

function addLube(room,data,token) {
  index = 0;
  while (token == null && index < 12) {
    token = (parseInt(Math.random()*90000)+10000);
    if (lubeTokens.indexOf(token) > -1) {
      token = null;
    }
    index ++;
  }
  lubeTokens.push(token);
  html = "<tr><td>"+data[0].value+"</td><td>"+data[1].value+"</td><td>"+data[2].value+" liters</td><td>"
  html += "<input type='hidden' name='lube[][room]' value='"+room+"'/>"
  html += "<input type='hidden' name='lube[][unit]' value='"+data[0].value+"'/>"
  html += "<input type='hidden' name='lube[][type]' value='"+data[1].value+"'/>"
  html += "<input type='hidden' name='lube[][amount]' value='"+data[2].value+"'/>"
  html += "<a class='lube-del' id='lube-del-"+token+"'><i class='material-icons red-text text-darken-4'>delete</i></a></td></tr>"
  $("#"+room+"_lubrication .card-action table tbody").append(html)
  $("#"+room+"_lubrication .card-action").slideDown();
  setLocal("lubrication_"+room+"_"+token,data[0].value+"|"+data[1].value+"|"+data[2].value,true);
}

function delLube(token) {
  tbody = $("#lube-del-"+token).closest("tbody");
  room = $("#lube-del-"+token).prevAll("input:last").val();
  $("#lube-del-"+token).closest("tr").remove();
  lubeTokens.splice(lubeTokens.indexOf(token),1);
  localStorage.removeItem("lubrication_"+room+"_"+String(token));
  if (tbody.find("tr").length == 0) {
    $("#"+room+"_lubrication .card-action").slideUp();
  }
}


// debug

function fillServer() {
  $.get("/localStorage",function(data){
    data = data.replace(/^\s*"/,"").replace(/"\s*$/,"").split("&")
    $.each(data,function(i,e){
      fill(e.split("="));
    })
    M.updateTextFields();
    checkInputs();
  })
}

function fillLocal() {
  for (var i = 0; i < localStorage.length; i++) {
    fill([localStorage.key(i),localStorage.getItem(localStorage.key(i))]);
  }
  M.updateTextFields();
  checkInputs();
}

function fill(d) {
  if (d[1] == "on") {
    input = $("input[name="+d[0]+"]");
    input.prop("checked",true)
  } else if (d[0].match(/_running/)) {
    $("select[name="+d[0]+"] option[value="+d[1]+"]").prop("selected",true)
    input = $("select[name="+d[0]+"]");
    input.formSelect();
    if ($("select[name="+d[0]+"]").closest(".input-field").hasClass("dev")) {
      //console.log($("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide."+$("select[name="+d[0]+"]").find("option:selected").val()));
      $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide").slideUp();
      $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide input").prop("required", false);
      $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide."+$("select[name="+d[0]+"]").find("option:selected").val()).slideDown();
      $("select[name="+d[0]+"]").closest(".dev").nextAll(".input-field.devhide."+$("select[name="+d[0]+"]").find("option:selected").val()).find("input").prop("required", true);
    }
  } else if (d[0].match(/^lubrication_/)) {
    room = d[0].split("_")[1]
    token = d[0].split("_")[2]
    data = d[1].split("|")
    addLube(room, [{name:"unit",value:data[0]},{name:"oil_type",value:data[1]},{name:"amount",value:data[2]}],token);
  } else {
    input = $("input[name="+d[0]+"]");
    input.val(d[1])
  }
  if (input.attr("type") != "hidden") {
    //console.log(input.attr("type"))
    check = input.closest(".card.system").find(".switch.sys input");
    check.prop("checked",true);
    toggleSystem(check);
  }
}
