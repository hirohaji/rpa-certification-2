*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library    Collections
Library    RPA.Archive
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Desktop
Library    RPA.FileSystem
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Tables
Library    RPA.RobotLogListener
Library    String

*** Variables ***
${START_PATH}=      https://robotsparebinindustries.com/#/robot-order
${DOWNLOAD_PATH}=   ${OUTPUT DIR}${/}orders.csv
${EXCEL_FILE_URL}=  https://robotsparebinindustries.com/orders.csv
${RECEIPTS_PATH}=   ${OUTPUT_DIR}${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Mute Run On Failure    Fill the form
    Open the robot order website
    ${table}=    Get orders
    ${orders}=    Table head    ${table}    as_list=True
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        ${Order number}=    Fill the form    ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}[0]
        ${screenshot}=    Take a screenshot of the robot    ${row}[0]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another Robot
    END
    Archive output PDF
    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${START_PATH}

Get orders
    Download    ${EXCEL_FILE_URL}    target_file=${DOWNLOAD_PATH}    overwrite=True
    Wait Until Created    ${DOWNLOAD_PATH}
    ${orders}=    Read table from CSV    ${DOWNLOAD_PATH}    header=True    delimiters=','
    RETURN    ${orders}

Close the annoying modal
    ${Button_OK}=    Convert To String    //../button[.="OK"]
    Click Button When Visible    ${Button_OK}


Click Order Button
    ${Button_Order}=    Convert To String    //../button[.="Order"]
    Click Button When Visible    ${Button_Order}
    ${Order number}=    Get WebElement  xpath://p[contains(@class,'badge-success')]


Fill the form
    [Arguments]    @{row}
    
    # get robot values from file
    ${Value_Order_number}=    Get From List    @{row}    0
    ${Value_Head}=    Get From List    @{row}    1
    ${Value_Body}=    Get From List    @{row}    2
    ${Value_Legs}=    Get From List    @{row}    3
    ${Value_Address}=    Get From List    @{row}    4

    # define the selectors for the input
    ${Selector_Head}=    Get WebElement    id:head
    ${Selector_Body}=    Convert To String    body
    ${Selector_Legs}=    Get WebElement    xpath://../input[contains(@placeholder,'legs')]
    ${Selector_Address}=    Get WebElement    xpath://input[@id='address']
    ${Button_Preview}=    Convert To String    //../button[.="Preview"]
    
    # input values for the robot
    Select From List By Value    ${Selector_Head}    ${Value_Head}
    Select Radio Button    ${Selector_Body}    ${Value_Body}
    Input Text    ${Selector_Legs}    ${Value_Legs}
    Input Text    ${Selector_Address}    ${Value_Address}

    # click the preview button
    Click Button When Visible    ${Button_Preview}

    # define the selectors for the preview image
    ${Image_Robot_Preview}=    Get WebElement    id:robot-preview-image
    ${Image_Head}=    Get WebElement    xpath://img[@alt='Head']
    ${Image_Body}=    Get WebElement    xpath://img[@alt='Body']
    ${Image_Legs}=    Get WebElement    xpath://img[@alt='Legs']

    # wait for the image
    Wait Until Element Is Visible    ${Image_Head}
    Wait Until Element Is Visible    ${Image_Body}
    Wait Until Element Is Visible    ${Image_Legs}
    
    # retry click the order button until succeeds
    Wait Until Keyword Succeeds    3    2    Click Order Button
    ${Order number}=    Get WebElement  xpath://p[contains(@class,'badge-success')]
    RETURN    Get Text     ${Order number}

Store the receipt as a PDF file
    [Arguments]    @{Order number}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${FILE_PATH}=    Convert To String    ${RECEIPTS_PATH}${/}${Order number}[0].pdf
    Html To Pdf    ${receipt}    ${FILE_PATH}
    RETURN    ${FILE_PATH}
    

Take a screenshot of the robot
    [Arguments]    ${Order number}
    ${image}=    Screenshot    id:robot-preview
    RETURN    ${image}
    

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
     ${files}=    Create List
     ...    ${pdf}
     ...    ${screenshot}:align=center
     Add Files To PDF    ${files}    ${pdf}


Order another Robot
    Click Button    id:order-another    

Archive output PDF
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${RECEIPTS_PATH}
    ...    ${zip_file_name}