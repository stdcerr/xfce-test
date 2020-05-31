@fixture.startXFCE4Clipman
Feature: For translations: Make all texts visible

#  Scenario: start clipman
#     Given we have xfce4-clipman started

#  Scenario: show the popup
#     Given we have xfce4-clipman started
#      when we popup clipman
#      then close it with <esc>
#       and close it with <esc>

  Scenario Outline: go through all settings
     Given we have xfce4-clipman started
       and we have xfce4-clipman-settings started in <lang>
      when we click on ptabActions in dlgClipmanSettings
#       and we click on btn0 in dlgClipmanSettings
#       and we click on btn0 in dlgEditAction
#       and we click on btnCancel in dlgRegularexpression
#       and we click on btnCancel in dlgEditAction
#       and we click on ptabHistory in dlgClipmanSettings
       and we click on btnClose in dlgClipmanSettings
   Examples: Languages
     | lang |
     | C |
     | automate.utf8 |
     | de_DE.utf8 |

#  Scenario: Open right-click menu
#     Given we find dlg1 which has mnuQuit by stupid-clicking frm0
#      when we click on mnuAbout somewhere
#       and we click on rbtnCredits in dlgAboutClipman
#       and we click on rbtnLicense in dlgAboutClipman
#      then close it with <esc>
