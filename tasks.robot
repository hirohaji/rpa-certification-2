*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             Collections
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Desktop
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library    String
Library    RPA.Archive



*** Variables ***
${START_PATH}=      https://robotsparebinindustries.com/#/robot-order
${DOWNLOAD_PATH}=   ${OUTPUT DIR}${/}orders.csv
${EXCEL_FILE_URL}=  https://robotsparebinindustries.com/orders.csv
${RECEIPTS_PATH}=   ${OUTPUT_DIR}${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${table}=    Get orders
    # Log    ${table}
    ${orders}=    Table head    ${table}    as_list=True
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        ${Order number}=    Fill the form    ${row}
        #Download and store the result
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
    # Download    ${EXCEL_FILE_URL}    target_file=${DOWNLOAD_PATH}    overwrite=True
    # Wait Until Created    ${DOWNLOAD_PATH}
    ${orders}=    Read table from CSV    ${DOWNLOAD_PATH}    header=True    delimiters=','
    RETURN    ${orders}

Close the annoying modal
    # Click Button When Visible    //../button[.="OK"]
    ${Button_OK}=    Convert To String    //../button[.="OK"]
    Click Button When Visible    ${Button_OK}


Click Order Button
    ${Button_Order}=    Convert To String    //../button[.="Order"]
    Click Button When Visible    ${Button_Order}
    ${Order number}=    Get WebElement  xpath://p[contains(@class,'badge-success')]
    #Wait Until Page Contains    "Receipt"    2
        #${Error_Message}=    Get WebElement    xpath://div[contains(@class,'alert-danger')]
        #${Receipt}=    Get WebElement    //div[@id='receipt']


Fill the form
    [Arguments]    @{row}
    # ${Order number}    ${Head}    ${Body}    ${Legs}    ${Address}
    # Log    ${row}[0][0]

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

    # wait for the image and screenshot
    Wait Until Element Is Visible    ${Image_Head}
    Wait Until Element Is Visible    ${Image_Body}
    Wait Until Element Is Visible    ${Image_Legs}
    # Wait For Element    ${Image_Robot_Preview}

    # retry click the order button until succeeds
    Wait Until Keyword Succeeds    3    2    Click Order Button
        # <p class="form-text text-muted">Requests can be submitted without a body, but not in our store. Pick up a body!</p>
        # <div id="receipt" class="alert alert-success" role="alert"><h3>Receipt</h3><div>2023-07-12T09:51:04.675Z</div><p class="badge badge-success">RSB-ROBO-ORDER-QLBHT1A6W</p><p>1</p><div id="parts" class="alert alert-light" role="alert"><div>Head: 1</div><div>Body: 1</div><div>Legs: 1</div></div><p>Thank you for your order! We will ship your robot to you as soon as our warehouse robots gather the parts you ordered! You will receive your robot in no time!</p></div>
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