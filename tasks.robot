*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Robocloud.Secrets
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Dialogs
Library    Collections
Library    OperatingSystem

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${prefix}=    Ask for receipt PDF prefix
    Open the robot order website
    ${orders}=    Get orders from server
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Close the modal
        Fill in the order form    ${order}
        ${imagefile}=    Take a screenshot of the robot
        Submit order
        ${pdf}=    Store order receipt as PDF    ${prefix}    ${order}[Order number]    output
        Embed image into receipt    ${pdf}    ${imagefile}
        Order another robot
    END
    [Teardown]  Clean up
    Log  Done.

*** Keywords ***
Get the store url from vault
    ${store}=    Get Secret    store
    ${url}=    Set Variable    ${store}[url]
    Log    ${url}
    [Return]    ${url}

Clean up
    [Documentation]    Close browser and remove files that are no longer needed.
    Close Browser
    Remove File    output/robot.png
    Remove File    data/orders.csv

Open the robot order website
    ${url}=    Get the store url from vault
    Open Available Browser    url=${url}

Get orders from server
    ${datafile}=    Set Variable    data/orders.csv
    Download    https://robotsparebinindustries.com/orders.csv
    ...    target_file=${datafile}
    ...    overwrite=True
    ${orders}=    Read Table From Csv    ${datafile}
    [Return]    ${orders}

Close the modal
    [Documentation]    Checks if the modal is visible and if it is, closes it.
    ${modalvisible}=    Is Element Visible    css:div.modal
    Run Keyword If    ${modalvisible}
    ...    Click Button    css:button.btn-dark

Fill in the order form
    [Arguments]    ${order}

    # head
    Select From List By Value    css:#head    ${order}[Head]
    Log    Head ${order}[Head] selected

    # body
    Select Radio Button    body    ${order}[Body]
    Log    Body ${order}[Body] selected

    # legs
    Input Text    xpath://form/div[3]/input[@type="number"]    ${order}[Legs]
    Log    Legs ${order}[Legs] selected

    # address
    Input Text    css:#address    ${order}[Address]
    Log    Address ${order}[Address] entered

    Click Button    css:#preview

Submit order
    [Documentation]    Submits order and retries if submitting the order fails.
    # try 5 times for submitting the order to succeed
    # wait 1 second before retrying
    Wait Until Keyword Succeeds    5x    1.0s    Click order button

Click order button
    Click Button    css:#order
    Element Should Not Be Visible    css:div.alert-danger

Order another robot
    Click Button    css:#order-another

Store order receipt as PDF
    [Documentation]    Stores order completion notification as a PDF file.
    [Arguments]    ${prefix}    ${ordernr}    ${targetpath}
    ${content}=    Get Element Attribute    css:div#order-completion    outerHTML
    ${pdfpath}=    Set Variable    ${targetpath}${/}${prefix}order-receipt-${ordernr}.pdf
    Html To Pdf    ${content}    ${pdfpath}
    [Return]    ${pdfpath}

Take a screenshot of the robot
    [Documentation]    Capture robot image from the web page. Returns absolute
    ...                path to the image file.
    ${image}=    Capture Element Screenshot    css:#robot-preview-image    robot.png
    [Return]    ${image}

Embed image into receipt
    [Documentation]    Adds the robot image as new page into the receipt document.
    [Arguments]    ${pdf}    ${image}
    @{images}=    Create List    ${pdf}    ${image}
    Add Files To Pdf    ${images}    ${pdf}

Ask for receipt PDF prefix
    [Documentation]    Ask the user if receipt file names should be prefixed
    ...                and what the prefix should be. Returns the prefix or
    ...                and empty string, if the user don't want to use prefix.
    Create Form
    Add Title    Receipt filename prefix
    Add Text Input    label=Prefix    name=prefix    value=robot
    Add Text    Use prefix?
    Add Radio Buttons    useprefix    options=yes,no    default=no
    ${result}=    Request Response
    ${prefix}=    Set Variable If    "${result}[useprefix]" == "yes"    ${result}[prefix]    ${EMPTY}
    [Return]    ${prefix}