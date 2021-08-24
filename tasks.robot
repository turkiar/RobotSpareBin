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
Library    Collections

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders from server
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Close the modal
        Fill in the order form    ${order}
        Submit order
        Exit For Loop
    END
    Log  Done.

*** Keywords ***
Get the store url from vault
    ${store}=    Get Secret    store
    ${url}=    Set Variable    ${store}[url]
    Log    ${url}
    [Return]    ${url}

Open the robot order website
    ${url}=    Get the store url from vault
    Open Available Browser    url=${url}
    #Open Browser    url=${url}    browser=firefox

Get orders from server
    ${datafile}=    Set Variable    data/orders.csv
    Download    https://robotsparebinindustries.com/orders.csv
    ...    target_file=${datafile}
    ...    overwrite=True
    ${orders}=    Read Table From Csv    ${datafile}
    [Return]    ${orders}

Close the modal
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
    Click Button    css:#order