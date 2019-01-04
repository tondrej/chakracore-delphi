object DataModuleMain: TDataModuleMain
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 265
  Width = 368
  object OpenDialog: TOpenDialog
    DefaultExt = '.js'
    Filter = 'Javascript files (*.js)|*.js|All files (*.*)|*.*'
    FilterIndex = 0
    Title = 'Open Javascript file'
    Left = 24
    Top = 8
  end
end
