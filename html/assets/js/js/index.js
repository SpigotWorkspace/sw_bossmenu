let fireIdentifier = null
let societyActionType = null
let hireIdentifier = null
let labelsSet = false
let locales = []

window.addEventListener('message', (event) => {
    if (event.data.type === 'open') {
        locales = event.data.locales;
        setLabels();
        const data = event.data.data;
        const allowedFeatures = data.allowedFeatures;
        $("[data-right]").hide()
        for (const [key, value] of Object.entries(allowedFeatures)) {
            const element = $("[data-right~='"+key+"']")
            if (value) {
                element.show();
            } else {
                element.hide();
            }
          }
        $('[class^="row ui-page-"]').css('display', 'none');
        $('.sidebar-button').removeClass('selected');
        $("#sidebar-subtitle").html(data.jobLabel);
        $("body").css('display', 'block');
    } else if (event.data.type === 'close') {
        $("body").css('display', 'none');
    }
})

function fillOverviewTable() {
    $('#table-body').children().remove();
    $.post("https://sw_bossmenu/getEmployeeData", JSON.stringify({}), function(data) {
        $('#table-body').append(
            `
            <tr class="warning no-result">
                <td colspan="12">`+translate("td_no_result")+`</td>
            </tr>
            `
        )
        let gradeToDisable = data.highestGrade - 1
        if (data.players.length == 0) {
            $('.no-result').show();
        } else {
            data.players.forEach(element => {
                let disabledPromote = ''
                let disabledDemote = ''
                let jobGrade = element.job_grade
        
                if (jobGrade == gradeToDisable) {
                    disabledPromote = 'disabled'
                } else if(jobGrade == 0) {
                    disabledDemote = 'disabled'
                }
                $('#table-body').append(
                    `
                    <tr>
                        <td>`+element.firstname+`</td>
                        <td>`+element.lastname+`</td>
                        <td>`+element.grade+`</td>
                        <td><button class="btn btn-promote" `+disabledPromote+` onclick="onActionButtonClick('`+element.identifier+`', 'promote')" style="margin-left: 5px;"><i class="fa-solid fa-user-plus" style="font-size: 15px;"></i></button>
                        <button class="btn btn-demote" `+disabledDemote+` onclick="onActionButtonClick('`+element.identifier+`', 'demote')" style="margin-left: 5px;"><i class="fa-solid fa-user-minus" style="font-size: 15px;"></i></button>
                        <button class="btn btn-fire" onclick="openFireConfirmationDialog('`+element.identifier+`', '`+element.grade+`', '`+element.firstname+`', '`+element.lastname+`')" style="margin-left: 5px;"><i class="fa-solid fa-user-xmark" style="font-size: 15px;"></i></button></td>
                    </tr>
                    `
                )
            });
        }
    });
    
}

function fillHireTable() {
    $('#table-body-hire').children().remove();
    $.post("https://sw_bossmenu/getHireData", JSON.stringify({}), function(data) {
        $('#table-body-hire').append(
            `
            <tr id="no-result-hire" class="warning no-result">
                <td colspan="12">`+translate("td_no_result")+`</td>
            </tr>
            `
        )
        if (data.length == 0) {
            $('#no-result-hire').show();
        } else {
            data.forEach(element => {
                $('#table-body-hire').append(
                    `
                    <tr>
                        <td>`+element.firstname+`</td>
                        <td>`+element.lastname+`</td>
                        <td><button class="btn btn-promote" onclick="openHireConfirmationDialog('`+element.identifier+`', '`+element.firstname+`', '`+element.lastname+`')" style="margin-left: 5px;"><i class="fa-solid fa-user-check" style="font-size: 15px;"></i></button></td>
                    </tr>
                    `
                )
            });
        }
    });
}

function setSocietyMoney() {
    $.post("https://sw_bossmenu/getSocietyMoney", JSON.stringify({}), function(money) {
        $("#balance-span").html(money + "€")
    });
}

function onActionButtonClick(identifier, action) {
    $.post("https://sw_bossmenu/onAction", JSON.stringify({identifier, action}), function (success) {
        if (success) {
            fillOverviewTable();
        }
      });
}

function openFireConfirmationDialog(identifier, grade, firstname, lastname) {
    this.fireIdentifier = identifier
    $("#modal-content-fire-p").html(formatString(translate('fire_dialog_content'), {grade, firstname, lastname}))
    $("#fireConfirmationDialog").css('display', 'block');
} 

function openHireConfirmationDialog(identifier, firstname, lastname) {
    this.hireIdentifier = identifier
    $("#modal-content-hire-p").html(formatString(translate('hire_dialog_content'), {firstname, lastname}))
    $("#hireConfirmationDialog").css('display', 'block');
} 

function openSocietyInputDialog(type) {
    $("#society-amount-input").val("")
    let text = '';
    this.societyActionType = type
    if (type == 'deposit') {
        text = translate('deposit')
    } else if(type == 'withdraw') {
        text = translate('withdraw')
    }
    $("#modal-title-society").html(formatString(translate('society_dialog_title'), {type: text}))
    $("#modal-content-society-p").html(formatString(translate('society_dialog_content'), {type: text.toLowerCase()}))
    $("#societyInputDialog").css('display', 'block');
  }

function modalDialogAction(action, type) {
    if (action == 'confirm') {
        switch (type) {
            case 'fire':
                if (this.fireIdentifier != null) {
                    $.post("https://sw_bossmenu/onAction", JSON.stringify({identifier: this.fireIdentifier, action: 'fire'}), function (success) {
                        if (success) {
                            fillOverviewTable();
                        }
                      });
                }
                break;
            case 'society':
                if (this.societyActionType != null) {
                    const amount = $("#society-amount-input").val()
                    if (amount) {
                        $.post("https://sw_bossmenu/societyAction", JSON.stringify({type: this.societyActionType, amount: amount}), function() {
                        setSocietyMoney();
                        });
                    }
                }
                break;
            case 'hire':
                if (this.hireIdentifier != null) {
                    $.post("https://sw_bossmenu/hirePlayer", JSON.stringify({identifier: this.hireIdentifier}), function (success) {
                        if (success) {
                            fillHireTable();
                        }
                      });
                }
                break;
            default:
                break;
        }
    }
    this.societyActionType = null;
    this.fireIdentifier = null;
    this.hireIdentifier = null;
    $(".modal").css('display', 'none');
}

function switchSite(name, element) {
    switch (name) {
        case 'overview':
            fillOverviewTable();
            break;
        case 'hire':
            fillHireTable();
            break;
        case 'account':
            setSocietyMoney();
            break;
        default:
            break;
    }
    $('[class^="row ui-page-"]').css('display', 'none');
    $('.ui-page-' + name).css('display', 'block');
    $('.sidebar-button').removeClass('selected');
    $(element).addClass('selected');
}

document.onkeydown = (event) => {
    const key = event.key;
    if (key == "Escape") {
        $.post("https://sw_bossmenu/close", JSON.stringify({}));
    }
}


function setLabels() {
    if (!labelsSet) {
        $('[data-locale]').each(function() {
            const locale = $(this).data('locale');
            $(this).html(translate(locale));
        });

        $("#search_input").attr('placeholder', translate("search_input_placeholder"))
        labelsSet = true
    }
}

function translate(locale) {
    const label = locales[locale]
    return label ? label : "No locale '" + locale + "' found"
}

function formatString(template, values) {
    return template.replace(/%(\w+)%/g, (match, key) => {
        return typeof values[key] !== 'undefined' ? values[key] : match;
    });
}

