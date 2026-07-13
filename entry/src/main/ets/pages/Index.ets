interface NoteCard {
  id: string
  title: string
  time: string
  body: string
  color: string
  list: boolean
  folder: string
  pinned: boolean
  labels: string[]
  items: ChecklistItem[]
}

interface ChecklistItem {
  text: string
  checked: boolean
}

@Entry
@Component
struct Index {
  @StorageLink('ui_state') phaseState: string = 'page_0000_notes_initial'
  @State maxTitleLines: number = 1
  @State maxListItems: number = 4
  @State maxNoteLines: number = 8
  @State viewMode: string = 'List'
  @State searchScope: string = 'Notes'
  @State labelName: string = 'Work'
  @State seededMode: string = '__unset__'
  @State notes: NoteCard[] = []
  @State labels: string[] = []
  @State selectedNoteId: string = ''
  @State selectedNoteIds: string[] = []
  @State editingNoteId: string = ''
  @State editorKind: string = 'text'
  @State editorTitleDraft: string = ''
  @State editorBodyDraft: string = ''
  @State editorItems: ChecklistItem[] = []
  @State editorItemDraft: string = ''
  @State editorPinActive: boolean = false
  @State editingChecklistIndex: number = -1
  @State editingChecklistDraft: string = ''
  @State searchText: string = ''
  @State labelDraft: string = ''
  @State activeDialog: string = ''
  @State labelPickerOrigin: string = ''
  @State labelPickerReturnState: string = ''
  @State labelDialogOrigin: string = ''

  private menuRows: string[] = ['Labels', 'Export', 'Change color', 'Make a copy', 'Delete', 'Archive']

  aboutToAppear() {
    this.applySeedMode()
  }

  onBackPress(): boolean {
    if (this.isLabelPicker()) {
      this.closeLabelPicker()
      return true
    }
    if (this.isActionMode()) {
      this.clearSelection()
      return true
    }
    return false
  }

  build() {
    Stack() {
      if (this.isEditor()) {
        this.EditorPage()
      } else if (this.isSearch()) {
        this.SearchPage()
      } else {
        this.TopLevelPage()
      }

      if (this.showFabs()) {
        this.FabStack()
      }

      if (this.isDrawer()) {
        this.DrawerOverlay()
      }

      if (this.isViewDialog()) {
        this.ViewDialog()
      }

      if (this.isLabelAddDialog()) {
        this.LabelAddDialog()
      }

      if (this.isLabelContextDialog()) {
        this.LabelContextDialog()
      }

      if (this.isActionMenu()) {
        this.ActionMenu()
      }

      if (this.isColorDialog()) {
        this.ColorDialog()
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  TopLevelPage() {
    if (this.isLabelPicker()) {
      this.LabelPickerPage()
    } else {
      Column() {
        this.AppBar(this.currentTitle(), this.isActionMode() ? 'back' : 'drawer')
        if (this.isSettings()) {
          this.SettingsBody()
        } else if (this.isLabels()) {
          this.LabelsBody()
        } else {
          this.NotesBody()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
    }
  }

  @Builder
  AppBar(title: string, navKind: string) {
    Row() {
      Row() {
        this.ToolbarNavIcon(navKind, this.toolbarFg())
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .key('toolbar_nav')
      .onClick(() => {
        if (navKind === 'drawer') {
          this.setState('page_0001_drawer_open')
        } else if (this.isActionMode()) {
          this.setState('page_0036_notes_after_action_back')
        } else if (navKind === 'back') {
          this.setState('page_0016_notes_after_text_save')
        } else {
          this.setState('page_0036_notes_after_action_back')
        }
      })

      Text(this.currentTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.toolbarFg())
        .layoutWeight(1)
        .maxLines(1)
        .margin({ left: 8 })

      if (this.isNotesLike() && !this.isActionMode()) {
        Image($r('app.media.search'))
          .width(24)
          .height(24)
          .fillColor(this.toolbarFg())
          .margin({ right: 18 })
          .key('toolbar_search')
          .onClick(() => this.setState('page_0022_search_initial'))
      }

      if (this.isLabels()) {
        Image($r('app.media.add'))
          .width(24)
          .height(24)
          .fillColor(this.toolbarFg())
          .margin({ right: 18 })
          .key('toolbar_add_label')
          .onClick(() => this.openLabelAddDialog())
      }

      if (this.isActionMode()) {
        Image($r('app.media.pin'))
          .width(23)
          .height(23)
          .fillColor(this.toolbarFg())
          .margin({ right: 18 })
          .key('action_pin')
          .onClick(() => this.toggleSelectedPin())
        Image($r('app.media.share'))
          .width(23)
          .height(23)
          .fillColor(this.toolbarFg())
          .margin({ right: 18 })
          .key('action_share')
          .onClick(() => this.setState('page_0035_action_mode_one_selected'))
        Row() {
          this.OverflowIcon(this.toolbarFg())
        }
          .width(44)
          .height(48)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .key('action_more')
          .onClick(() => this.openActionMenu())
      }

      if (this.phaseState.indexOf('deleted') >= 0 && !this.isActionMode()) {
        Image($r('app.media.delete_all'))
          .width(24)
          .height(24)
          .fillColor(this.toolbarFg())
          .margin({ right: 18 })
          .key('toolbar_delete_all')
          .onClick(() => this.deleteAllDeleted())
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 4, right: 4 })
    .backgroundColor(this.toolbarBg())
    .alignItems(VerticalAlign.Center)
    .shadow({ radius: this.isActionMode() ? 0 : 2, color: '#22000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  ToolbarNavIcon(navKind: string, color: string) {
    if (navKind === 'drawer') {
      this.HamburgerIcon(color)
    } else if (navKind === 'back') {
      this.BackIconFixed(color)
    } else {
      this.CloseIconFixed(color)
    }
  }

  @Builder
  HamburgerIcon(color: string) {
    Column() {
      Row().width(22).height(2).backgroundColor(color).borderRadius(1)
      Row().width(22).height(2).backgroundColor(color).borderRadius(1).margin({ top: 5 })
      Row().width(22).height(2).backgroundColor(color).borderRadius(1).margin({ top: 5 })
    }
    .width(26)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BackIconFixed(color: string) {
    Image($r('app.media.previous'))
      .width(24)
      .height(24)
      .fillColor(color)
  }

  @Builder
  CloseIconFixed(color: string) {
    Stack() {
      Row().width(24).height(2).backgroundColor(color).borderRadius(1).rotate({ angle: 45 })
      Row().width(24).height(2).backgroundColor(color).borderRadius(1).rotate({ angle: -45 })
    }
    .width(28)
    .height(28)
  }

/*
  @Builder
  BackIcon(color: string) {
    Text('‹')
      .fontSize(36)
      .fontColor(color)
      .lineHeight(40)
      .fontWeight(FontWeight.Medium)
  }

  @Builder
  CloseIcon(color: string) {
    Text('×')
      .fontSize(28)
      .fontColor(color)
      .lineHeight(36)
  }

*/

  @Builder
  OverflowIcon(color: string) {
    Column() {
      Row().width(4).height(4).backgroundColor(color).borderRadius(2)
      Row().width(4).height(4).backgroundColor(color).borderRadius(2).margin({ top: 4 })
      Row().width(4).height(4).backgroundColor(color).borderRadius(2).margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  NotesBody() {
    Column() {
      if (this.noteCards().length > 0) {
        ForEach(this.noteCards(), (note: NoteCard) => {
          this.NoteCardView(note)
        }, (note: NoteCard) => note.title + note.time)
      } else {
        this.EmptyStateImage(this.emptyMedia())
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 10, left: 8, right: 8, bottom: 144 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  NoteCardView(note: NoteCard) {
    Column() {
      Row()
        .width('100%')
        .height(4)
        .backgroundColor(note.color)
        .border({ width: 1, color: '#D0D0D0' })
        .margin({ bottom: 8 })
        .key(this.noteColorKey(note))

      Row() {
        Text(note.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#202124')
          .maxLines(this.maxTitleLines)
          .layoutWeight(1)
        if (note.pinned) {
          Image($r('app.media.pin'))
            .width(18)
            .height(18)
            .fillColor('#555555')
            .key(this.noteKey(note) + '_pin')
        }
      }
      .width('100%')

      Text(note.time)
        .fontSize(13)
        .fontColor('#777777')
        .margin({ top: 4 })
        .width('100%')

      if (note.body.length > 0 && !note.list) {
        Text(note.body)
          .fontSize(15)
          .fontColor('#424242')
          .maxLines(this.maxNoteLines)
          .margin({ top: 8 })
          .width('100%')
      }

      if (note.list) {
        ForEach(note.items.slice(0, this.maxListItems), (item: ChecklistItem) => {
          Row() {
            if (item.checked) {
              Stack() {
                Row().width(18).height(18).backgroundColor('#111111')
                Row().width(7).height(2).backgroundColor('#FFFFFF').rotate({ angle: 45 }).position({ x: 3, y: 10 })
                Row().width(11).height(2).backgroundColor('#FFFFFF').rotate({ angle: -45 }).position({ x: 7, y: 8 })
              }
              .width(18)
              .height(18)
              .margin({ right: 12 })
            } else {
              Image($r('app.media.checkbox_outline'))
                .width(18)
                .height(18)
                .fillColor('#666666')
                .margin({ right: 12 })
            }
            Text(item.text)
              .fontSize(15)
              .fontColor('#424242')
              .layoutWeight(1)
          }
          .margin({ top: 8 })
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }, (item: ChecklistItem) => item.text)
      }

      if (this.isSelectedCard(note)) {
        Row() {
          Blank().layoutWeight(1)
          Image($r('app.media.checked_circle'))
            .width(24)
            .height(24)
            .fillColor('#03A9F4')
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor(this.isSelectedCard(note) ? '#E3F2FD' : '#FFFFFF')
    .border({ width: this.isSelectedCard(note) ? 2 : 1, color: this.isSelectedCard(note) ? '#03A9F4' : '#D0D0D0' })
    .borderRadius(2)
    .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })
    .key(this.noteKey(note))
    .onClick(() => {
      if (this.isActionMode()) {
        this.toggleSelection(note.id)
      } else if (note.list) {
        this.openExistingEditor(note.id)
      } else {
        this.openExistingEditor(note.id)
      }
    })
    .gesture(LongPressGesture().onAction(() => this.enterSelection(note.id)))
  }

  @Builder
  LabelsBody() {
    Column() {
      if (this.labels.length > 0 || this.hasWorkLabel()) {
        ForEach(this.visibleLabels(), (label: string) => {
          Row() {
            Text(label)
              .fontSize(18)
              .fontColor('#222222')
              .layoutWeight(1)
          }
          .width('100%')
          .height(56)
          .padding({ left: 24, right: 20 })
          .backgroundColor('#FFFFFF')
          .key(label === 'Work' ? 'label_row_work' : 'label_row_' + label.toLowerCase().replace(' ', '_'))
          .onClick(() => this.openLabelNotes(label))
          .gesture(LongPressGesture().onAction(() => this.openLabelContext(label)))
        }, (label: string) => label)
      } else {
        this.EmptyStateImage($r('app.media.label'))
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  LabelPickerPage() {
    Column() {
      Row() {
        Row() {
          this.BackIconFixed('#555555')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .key('label_picker_back')
        .onClick(() => this.closeLabelPicker())
        Text('Labels')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .layoutWeight(1)
          .margin({ left: 8 })
        Image($r('app.media.add'))
          .width(24)
          .height(24)
          .fillColor('#555555')
          .margin({ right: 18 })
          .key('toolbar_add_label')
          .onClick(() => this.openLabelAddDialog())
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

      Column() {
        ForEach(this.visibleLabels(), (label: string) => {
          Row() {
            Text(label)
              .fontSize(18)
              .fontColor('#222222')
              .layoutWeight(1)
            if (this.pickerNoteHasLabel(label)) {
              Image($r('app.media.checked_circle'))
                .width(24)
                .height(24)
                .fillColor('#03A9F4')
                .key(label === 'Work' ? 'label_picker_work_checked' : 'label_picker_custom_checked')
            } else {
              Image($r('app.media.checkbox_outline'))
                .width(24)
                .height(24)
                .fillColor('#666666')
                .key(label === 'Work' ? 'label_picker_work_unchecked' : 'label_picker_custom_unchecked')
            }
          }
          .width('100%')
          .height(56)
          .padding({ left: 24, right: 20 })
          .backgroundColor('#FFFFFF')
          .key(label === 'Work' ? 'label_picker_row_work' : 'label_picker_row_custom')
          .onClick(() => this.togglePickerLabel(this.pickerNoteId(), label))
        }, (label: string) => label)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .key('label_picker')
  }

  @Builder
  EmptyStateImage(icon: Resource) {
    Column() {
      Blank().height(300)
      Image(icon)
        .width(84)
        .height(84)
        .fillColor('#03A9F4')
      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SettingsBody() {
    Scroll() {
      Column() {
        this.SectionTitle('Appearance')
        this.PreferenceRow('View', this.viewMode, 'pref_view', 'view')
        this.PreferenceRow('Theme', 'Follow system', 'pref_theme', 'theme')
        this.PreferenceRow('Date format', '1 day ago', 'pref_date_format', 'date_format')
        this.PreferenceRow('Text size', 'Medium', 'pref_text_size', 'text_size')

        this.SectionDivider()
        this.SectionTitle('Content density')
        this.SliderPreference('Max lines to display in title', this.titleSliderValue(), 1, 5, 'slider_max_title')
        this.SliderPreference('Max items to display in list', this.maxListItems, 1, 8, 'slider_max_items')
        this.SliderPreference('Max lines to display in note', this.maxNoteLines, 1, 10, 'slider_max_note')

        this.SectionDivider()
        this.SectionTitle('Backup')
        this.PreferenceRow('Auto backup', 'Tap to set up', 'pref_auto_backup', 'none')
        this.SimpleRow('Import backup', 'settings_row_import_backup')
        this.SimpleRow('Export backup', 'settings_row_export_backup')

        this.SectionDivider()
        this.SectionTitle('Others')
        this.SimpleRow('GitHub', 'settings_row_github')
        this.SimpleRow('Rate this app', 'settings_row_rate')
        this.SimpleRow('Send feedback', 'settings_row_feedback')
        this.SimpleRow('Libraries', 'settings_row_libraries')
      }
      .width('100%')
      .padding({ bottom: 28 })
    }
    .layoutWeight(1)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#03A9F4')
      .width('100%')
      .height(42)
      .padding({ left: 16, top: 14 })
      .backgroundColor('#FFFFFF')
  }

  @Builder
  SectionDivider() {
    Row()
      .width('100%')
      .height(1)
      .backgroundColor('#E0E0E0')
  }

  @Builder
  PreferenceRow(title: string, value: string, keyName: string, actionKey: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor('#222222')
        .width('100%')
      Text(value)
        .fontSize(14)
        .fontColor('#777777')
        .margin({ top: 2 })
        .width('100%')
    }
    .width('100%')
    .height(62)
    .padding({ left: 16, right: 16, top: 8 })
    .backgroundColor('#FFFFFF')
    .key(keyName)
    .onClick(() => {
      if (actionKey === 'view') {
        this.openDialog('view')
      } else if (actionKey !== 'none') {
        this.openDialog(actionKey)
      }
    })
  }

  @Builder
  SimpleRow(title: string, keyName: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#222222')
        .layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .key(keyName)
    .onClick(() => this.setState('page_0010_settings'))
  }

  @Builder
  SliderPreference(title: string, value: number, min: number, max: number, keyName: string) {
    Column() {
      Row() {
        Text(title)
          .fontSize(16)
          .fontColor('#222222')
          .layoutWeight(1)
      }
      .width('100%')
      Slider({ value: value, min: min, max: max, step: 1 })
        .width('100%')
        .selectedColor('#03A9F4')
        .trackColor('#D6D6D6')
        .blockColor('#03A9F4')
        .key(keyName)
        .onChange((newValue: number) => {
          this.setState('page_0011_settings_after_seekbar')
        })
    }
    .width('100%')
    .height(78)
    .padding({ left: 12, right: 12, top: 6 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SearchPage() {
    Column() {
      Row() {
        Row() {
          this.BackIconFixed('#444444')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .key('search_back')
        .onClick(() => this.closeSearch())

        TextInput({ text: this.searchQuery(), placeholder: 'Search' })
          .height(44)
          .layoutWeight(1)
          .fontSize(18)
          .fontColor('#222222')
          .placeholderColor('#777777')
          .backgroundColor('#FFFFFF')
          .key('search_input')
          .onChange((value: string) => {
            this.searchText = value
            this.setState(value.length > 0 ? 'page_0023_search_alpha_results' : 'page_0022_search_initial')
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 4, right: 16 })
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

      Row() {
        this.ScopeChip('Notes', 'page_0028_search_notes_scope', this.searchScopeForState(this.phaseState) === 'Notes')
        this.ScopeChip('Deleted', 'page_0026_search_deleted_scope', this.searchScopeForState(this.phaseState) === 'Deleted')
        this.ScopeChip('Archived', 'page_0027_search_archived_scope', this.searchScopeForState(this.phaseState) === 'Archived')
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Column() {
        if (this.searchQuery().length > 0) {
          if (this.searchResults().length > 0) {
            ForEach(this.searchResults(), (note: NoteCard) => {
              this.NoteCardView(note)
            }, (note: NoteCard) => note.id)
          } else {
            this.SearchEmptyStateImage()
          }
        } else {
          this.SearchEmptyStateImage()
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 8, right: 8, top: 10, bottom: 40 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  ScopeChip(title: string, targetState: string, selected: boolean) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(selected ? '#03A9F4' : '#222222')
    }
    .height(34)
    .padding({ left: 14, right: 14 })
    .margin({ right: 16 })
    .borderRadius(17)
    .border({ width: 1, color: selected ? '#03A9F4' : '#33000000' })
    .backgroundColor(selected ? '#E3F2FD' : '#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .key(this.scopeKey(title))
    .onClick(() => {
      this.searchScope = title
      this.setState(targetState)
    })
  }

  @Builder
  SearchEmptyStateImage() {
    if (this.needsCenteredSearchEmptyState()) {
      Column() {
        Blank().layoutWeight(1)
        Image($r('app.media.search'))
          .width(84)
          .height(84)
          .fillColor('#03A9F4')
        Blank().layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    } else {
      this.EmptyStateImage($r('app.media.search'))
    }
  }

  @Builder
  EditorPage() {
    Column() {
      Row() {
        Row() {
          this.BackIconFixed('#555555')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .key('editor_back_save')
        .onClick(() => this.closeEditorShell())
        Blank().layoutWeight(1)
        Row() {
          Image($r('app.media.pin'))
            .width(23)
            .height(23)
            .fillColor('#555555')
            .key(this.editorPinned() ? 'editor_pin_pinned' : 'editor_pin_unpinned')
        }
        .width(23)
        .height(23)
        .margin({ right: 18 })
        .key('editor_pin')
        .onClick(() => this.toggleEditorPin())
        Image($r('app.media.share'))
          .width(23)
          .height(23)
          .fillColor('#555555')
          .margin({ right: 18 })
          .key('editor_share')
          .onClick(() => this.setState(this.isListEditor() ? 'page_0017_make_list_new' : 'page_0015_take_note_filled'))
        Row() {
          this.OverflowIcon('#555555')
        }
          .width(44)
          .height(48)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .key('editor_more')
          .onClick(() => this.openEditorMenu())
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

      Column() {
        TextInput({ text: this.editorTitle(), placeholder: 'Title' })
          .height(58)
          .fontSize(22)
          .fontColor('#222222')
          .backgroundColor('#FFFFFF')
          .padding({ left: 16, right: 16 })
          .key('editor_title')
          .onChange((value: string) => {
            this.editorTitleDraft = value
            if (!this.isListEditor()) {
              this.setState('page_0015_take_note_filled')
            }
          })

        Text(this.editorDate())
          .fontSize(14)
          .fontColor('#777777')
          .width('100%')
          .height(48)
          .padding({ left: 16, top: 14 })
          .backgroundColor('#FFFFFF')

        if (this.isListEditor()) {
          this.ListEditorBody()
        } else {
          TextInput({ text: this.editorBody(), placeholder: 'Note' })
            .height(160)
            .fontSize(18)
            .fontColor('#222222')
            .backgroundColor('#FFFFFF')
            .padding({ left: 16, right: 16 })
            .key('editor_note_body')
            .onChange((value: string) => {
              this.editorBodyDraft = value
              this.setState('page_0015_take_note_filled')
            })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ListEditorBody() {
    Column() {
      if (this.editorItems.length > 0) {
        ForEach(this.editorItems, (item: ChecklistItem, index: number) => {
          this.ListItemRow(item.checked, item.text, 'list_item_saved_' + index, index)
        }, (item: ChecklistItem) => item.text + (item.checked ? '_checked' : '_open'))
      }
      Row() {
        Image($r('app.media.checkbox_outline'))
          .width(22)
          .height(22)
          .fillColor('#666666')
          .margin({ left: 14, right: 8 })
          .key('list_item_checkbox')
          .onClick(() => this.toggleEditorDraftItem())
        TextInput({ text: this.listItemText(), placeholder: 'Item' })
          .height(54)
          .fontSize(17)
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .key('list_item_input')
          .onChange((value: string) => {
            this.editorItemDraft = value
            if (value.length > 0) {
              this.setState('page_0019_make_list_item_text')
            }
          })
        Image($r('app.media.drag_handle'))
          .width(24)
          .height(24)
          .fillColor('#777777')
          .margin({ left: 8, right: 14 })
          .key('list_item_drag_handle')
      }
      .height(58)
      .width('100%')
      .backgroundColor('#FFFFFF')

      Row() {
        Image($r('app.media.add'))
          .width(22)
          .height(22)
          .fillColor('#777777')
          .margin({ right: 10 })
        Text('Add Item')
          .fontSize(16)
          .fontColor('#222222')
      }
      .height(56)
      .width('100%')
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .key('add_item_button')
      .onClick(() => this.addEditorItem())
    }
  }

  @Builder
  ListItemRow(checked: boolean, text: string, keyName: string, index: number) {
    Row() {
      if (checked) {
        Stack() {
          Row()
            .width(22)
            .height(22)
            .backgroundColor('#111111')
          Row()
            .width(8)
            .height(2)
            .backgroundColor('#FFFFFF')
            .rotate({ angle: 45 })
            .position({ x: 4, y: 12 })
          Row()
            .width(13)
            .height(2)
            .backgroundColor('#FFFFFF')
            .rotate({ angle: -45 })
            .position({ x: 9, y: 10 })
        }
        .width(22)
        .height(22)
        .margin({ left: 14, right: 8 })
        .key(keyName + '_checkbox_checked')
        .onClick(() => this.toggleSavedEditorItem(index))
      } else {
        Image($r('app.media.checkbox_outline'))
          .width(22)
          .height(22)
          .fillColor('#666666')
          .margin({ left: 14, right: 8 })
          .key(keyName + '_checkbox_unchecked')
          .onClick(() => this.toggleSavedEditorItem(index))
      }
      if (this.editingChecklistIndex === index) {
        TextInput({ text: this.editingChecklistDraft, placeholder: 'Item' })
          .fontSize(17)
          .fontColor('#222222')
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .key(keyName + '_edit_input')
          .onChange((value: string) => {
            this.editingChecklistDraft = value
          })
      } else {
        Text(text)
          .fontSize(17)
          .fontColor('#222222')
          .layoutWeight(1)
      }
      Image($r('app.media.edit'))
        .width(22)
        .height(22)
        .fillColor('#666666')
        .margin({ left: 8 })
        .key(keyName + '_edit')
        .onClick(() => this.beginSavedEditorItemEdit(index))
      Image($r('app.media.delete'))
        .width(22)
        .height(22)
        .fillColor('#666666')
        .margin({ left: 10 })
        .key(keyName + '_delete')
        .onClick(() => this.deleteSavedEditorItem(index))
      Image($r('app.media.drag_handle'))
        .width(24)
        .height(24)
        .fillColor('#777777')
        .margin({ left: 8, right: 14 })
        .key(keyName + '_drag_handle')
    }
    .height(58)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .key(keyName)
  }

  @Builder
  FabStack() {
    Column() {
      Blank().layoutWeight(1)
      Row() {
        Blank().layoutWeight(1)
        Column() {
          this.FabButton('make_list_fab', true)
          this.FabButton('take_note_fab', false)
        }
        .margin({ right: 16, bottom: 22 })
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  FabButton(keyName: string, list: boolean) {
    Row() {
      Image(list ? $r('app.media.make_list_foreground') : $r('app.media.take_note_foreground'))
        .width(list ? 30 : 34)
        .height(list ? 30 : 34)
        .fillColor(list ? '#03A9F4' : '#FFFFFF')
    }
    .width(list ? 48 : 56)
    .height(list ? 48 : 56)
    .borderRadius(list ? 24 : 14)
    .backgroundColor(list ? '#E3F2FD' : '#03A9F4')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ top: 14 })
    .shadow({ radius: 4, color: '#44000000', offsetX: 0, offsetY: 2 })
    .key(keyName)
    .onClick(() => this.openNewEditor(list))
  }

  @Builder
  DrawerOverlay() {
    Row() {
      Column() {
        Text('Notally')
          .fontSize(18)
          .fontColor('#03A9F4')
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .height(58)
          .padding({ left: 18, top: 26 })
          .backgroundColor('#FFFFFF')

        this.DrawerRow('Notes')
        this.DrawerDivider()
        this.DrawerRow('Labels')
        this.DrawerDivider()
        this.DrawerRow('Deleted')
        this.DrawerRow('Archived')
        this.DrawerDivider()
        this.DrawerRow('Settings')
      }
      .width('63%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 10, color: '#44000000', offsetX: 2, offsetY: 0 })

      Blank()
        .layoutWeight(1)
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => this.closeDrawer())
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .key('drawer_overlay')
  }

  @Builder
  DrawerRow(row: string) {
    Row() {
      Image(this.drawerIcon(row))
        .width(21)
        .height(21)
        .fillColor(this.drawerSelected(row) ? '#03A9F4' : '#666666')
        .margin({ left: 18, right: 20 })
      Text(row)
        .fontSize(15)
        .fontColor(this.drawerSelected(row) ? '#03A9F4' : '#222222')
        .fontWeight(this.drawerSelected(row) ? FontWeight.Medium : FontWeight.Regular)
    }
    .height(48)
    .width('100%')
    .backgroundColor(this.drawerSelected(row) ? '#E3F2FD' : '#FFFFFF')
    .alignItems(VerticalAlign.Center)
    .key('drawer_row_' + row.toLowerCase())
    .onClick(() => this.navigateDrawer(row))
  }

  @Builder
  DrawerDivider() {
    Row()
      .width('100%')
      .height(1)
      .margin({ left: 60 })
      .backgroundColor('#E0E0E0')
  }

  @Builder
  ViewDialog() {
    Column() {
      Column() {
        Text(this.settingsDialogTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .width('100%')
          .margin({ bottom: 14 })
        if (this.activeDialog === 'theme') {
          this.DialogChoice('Follow system', true, 'settings_noop')
          this.DialogChoice('Light', false, 'settings_noop')
          this.DialogChoice('Dark', false, 'settings_noop')
        } else if (this.activeDialog === 'date_format') {
          this.DialogChoice('1 day ago', true, 'settings_noop')
          this.DialogChoice('Jul 1, 2026', false, 'settings_noop')
          this.DialogChoice('2026-07-01', false, 'settings_noop')
        } else if (this.activeDialog === 'text_size') {
          this.DialogChoice('Small', false, 'settings_noop')
          this.DialogChoice('Medium', true, 'settings_noop')
          this.DialogChoice('Large', false, 'settings_noop')
        } else {
          this.DialogChoice('List', this.viewMode === 'List', 'view_list')
          this.DialogChoice('Grid', this.viewMode === 'Grid', 'view_grid')
        }
        Row() {
          Blank().layoutWeight(1)
          Text('Cancel')
            .fontSize(16)
            .fontColor('#03A9F4')
            .padding({ left: 22, right: 22, top: 12, bottom: 12 })
            .key('dialog_cancel')
            .onClick(() => this.closeDialog())
        }
        .width('100%')
      }
      .width('80%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(2)
      .shadow({ radius: 18, color: '#44000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .position({ x: 0, y: 0 })
  }

  @Builder
  LabelAddDialog() {
    Column() {
      Column() {
        Text('Add label')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .width('100%')
          .margin({ bottom: 16 })
        TextInput({ text: this.labelDialogText(), placeholder: this.labelDialogText().length > 0 ? 'Name' : '' })
          .height(44)
          .fontSize(16)
          .fontColor('#222222')
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#03A9F4' })
          .borderRadius(2)
          .key('label_name_input')
          .onChange((value: string) => {
            this.labelName = value
            this.labelDraft = value
            if (value.length > 0) {
              this.setState('page_0042_labels_add_dialog_filled')
            }
          })
        Row() {
          Blank().layoutWeight(1)
          Text('Cancel')
            .fontSize(16)
            .fontColor('#03A9F4')
            .padding({ left: 16, right: 16, top: 10, bottom: 8 })
            .key('label_cancel')
            .onClick(() => this.cancelLabelDialog())
          Text('Save')
            .fontSize(16)
            .fontColor('#03A9F4')
            .padding({ left: 16, right: 16, top: 10, bottom: 8 })
            .key('label_save')
            .onClick(() => this.saveLabelDialog())
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .width('83%')
      .padding(22)
      .backgroundColor('#FFFFFF')
      .borderRadius(2)
      .shadow({ radius: 18, color: '#44000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .position({ x: 0, y: 0 })
  }

  @Builder
  LabelContextDialog() {
    Column() {
      Column() {
        this.LabelContextSheetRow('Edit', 'label_context_edit')
        this.LabelContextSheetRow('Delete', 'label_context_delete')
      }
      .width('100%')
      .height(96)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .position({ x: 0, y: 0 })
  }

  @Builder
  LabelContextSheetRow(title: string, keyName: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#222222')
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .key(keyName)
    .onClick(() => this.handleLabelContext(title))
  }

  @Builder
  ActionMenu() {
    Column() {
      ForEach(this.actionMenuRows(), (item: string) => {
        Row() {
          Text(item)
            .fontSize(16)
            .fontColor('#222222')
            .layoutWeight(1)
          if (item === 'Export') {
            Text('>')
              .fontSize(18)
              .fontColor('#555555')
          }
        }
          .width('100%')
          .height(48)
          .padding({ left: 18, right: 16 })
          .alignItems(VerticalAlign.Center)
          .key(this.actionMenuKey(item))
          .onClick(() => this.handleActionMenu(item))
      }, (item: string) => item)
    }
    .width(184)
    .backgroundColor('#FFFFFF')
    .borderRadius(2)
    .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 2 })
    .position({ x: 162, y: 0 })
    .key('action_overflow_menu')
  }

  @Builder
  ColorDialog() {
    Column() {
      Column() {
        Text('Change color')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .width('100%')
          .margin({ bottom: 18 })
        Row({ space: 18 }) {
          this.ColorSwatch('Yellow', '#FFF59D', 'color_swatch_yellow')
          this.ColorSwatch('Blue', '#90CAF9', 'color_swatch_blue')
          this.ColorSwatch('White', '#FFFFFF', 'color_swatch_default')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        Row() {
          Blank().layoutWeight(1)
          Text('Cancel')
            .fontSize(16)
            .fontColor('#03A9F4')
            .padding({ left: 22, right: 22, top: 14, bottom: 10 })
            .key('color_dialog_cancel')
            .onClick(() => {
              this.activeDialog = ''
              this.setState('page_0035_action_mode_one_selected')
            })
        }
        .width('100%')
      }
      .width('82%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(2)
      .shadow({ radius: 18, color: '#44000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#66000000')
    .position({ x: 0, y: 0 })
    .key('color_dialog')
  }

  @Builder
  ColorSwatch(title: string, color: string, keyName: string) {
    Column({ space: 6 }) {
      Row()
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor(color)
        .border({ width: 1, color: '#777777' })
      Text(title)
        .fontSize(13)
        .fontColor('#333333')
    }
    .alignItems(HorizontalAlign.Center)
    .key(keyName)
    .onClick(() => this.applySelectedColor(color))
  }

  @Builder
  DialogChoice(title: string, selected: boolean, actionKey: string) {
    Row() {
      Stack() {
        Row()
          .width(20)
          .height(20)
          .borderRadius(10)
          .border({ width: 2, color: selected ? '#03A9F4' : '#777777' })
        if (selected) {
          Row()
            .width(10)
            .height(10)
            .borderRadius(5)
            .backgroundColor('#03A9F4')
            .key('dialog_selected_' + this.settingsChoiceToken(title))
        }
      }
      .width(36)
      .height(36)
      Text(title)
        .fontSize(17)
        .fontColor('#222222')
    }
    .height(52)
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .key('dialog_choice_' + title.toLowerCase())
    .onClick(() => {
      if (actionKey === 'view_list') {
        this.closeDialog()
      } else if (actionKey === 'view_grid') {
        this.closeDialog()
      } else if (actionKey === 'settings_noop') {
        this.closeDialog()
      }
    })
  }

  private applySeedMode() {
    if (this.seededMode === 'default') {
      return
    }
    this.seededMode = 'default'
    if (this.notes.length === 0) {
      const sampleText = this.makeTextNote(
        'alpha', 'Sample Note Title', 'Sample note body alpha', 'notes')
      sampleText.labels = ['Work']
      this.notes = [
        sampleText,
        this.makeListNote('groceries', 'Sample Checklist', [
          this.makeItem('Alpha item', false),
          this.makeItem('Beta item', false),
          this.makeItem('Groceries', false)
        ], 'notes'),
        this.makeTextNote(
          'density',
          'A deliberately long title that wraps across several lines for density settings',
          'A deliberately long note body that wraps across several lines so the maximum note line preference has a visible effect on the card.',
          'notes'),
        this.makeTextNote(
          'deleted_sample',
          'Deleted Sample Note',
          'Deleted sample body alpha',
          'deleted'),
        this.makeTextNote(
          'archived_sample',
          'Archived Sample Note',
          'Archived sample body alpha',
          'archived')
      ]
    }
    if (this.labels.length === 0) {
      this.labels = ['Work']
    }
    this.seedPhaseVisualData(this.phaseState)
  }

  private seedPhaseVisualData(state: string) {
    if (state.indexOf('page_0014_take_note_new') >= 0) {
      this.editorKind = 'text'
      this.editingNoteId = ''
      this.editorTitleDraft = ''
      this.editorBodyDraft = ''
      this.editorItems = []
      this.editorItemDraft = ''
    }
    if (state.indexOf('page_0015_take_note_filled') >= 0) {
      this.editorKind = 'text'
      this.editingNoteId = 'alpha'
      this.editorTitleDraft = 'Alpha'
      this.editorBodyDraft = 'keyword'
      this.editorItems = []
      this.editorItemDraft = ''
    }
    if (state.indexOf('after_text_save') >= 0 || state.indexOf('search') >= 0 || state.indexOf('before_action') >= 0 ||
      state.indexOf('action_mode') >= 0 || state.indexOf('after_action') >= 0 || state.indexOf('after_list_save') >= 0) {
      this.notes = [
        this.makeListNote('groceries', 'Groceries', [this.makeItem('milk', false)], 'notes'),
        this.makeTextNote('alpha', 'Alpha', 'keyword', 'notes')
      ]
    }
    if (state.indexOf('archived_with_item') >= 0) {
      this.notes = [this.makeTextNote('alpha', 'Alpha', 'keyword', 'archived')]
    }
    if (state.indexOf('with_work') >= 0 || state.indexOf('context') >= 0) {
      this.labels = ['Work']
    }
  }

  private makeTextNote(id: string, title: string, body: string, folder: string): NoteCard {
    return { id: id, title: title, time: 'moments ago', body: body, color: '#FFFFFF', list: false, folder: folder, pinned: false, labels: [], items: [] }
  }

  private makeListNote(id: string, title: string, items: ChecklistItem[], folder: string): NoteCard {
    return { id: id, title: title, time: 'moments ago', body: '', color: '#FFFFFF', list: true, folder: folder, pinned: false, labels: [], items: items }
  }

  private makeItem(text: string, checked: boolean): ChecklistItem {
    return { text: text, checked: checked }
  }

  private setState(state: string) {
    this.phaseState = state
    AppStorage.setOrCreate('ui_state', state)
    if (this.isSearchState(state)) {
      this.searchScope = this.searchScopeForState(state)
    }
  }

  private currentTitle(): string {
    if (this.isActionMode()) {
      return this.selectedCount().toString()
    }
    if (this.isSettings()) {
      return 'Settings'
    }
    if (this.isLabels()) {
      return 'Labels'
    }
    if (this.phaseState.indexOf('deleted') >= 0) {
      return 'Deleted'
    }
    if (this.phaseState.indexOf('archived') >= 0) {
      return 'Archived'
    }
    return 'Notally'
  }

  private toolbarBg(): string {
    return '#FFFFFF'
  }

  private toolbarFg(): string {
    return '#333333'
  }

  private noteCards(): NoteCard[] {
    const folder = this.currentFolder()
    let rows: NoteCard[] = []
    this.notes.forEach((note: NoteCard) => {
      if (note.folder === folder) {
        rows = rows.concat([note])
      }
    })
    return rows
  }

  private titleSliderValue(): number {
    return this.maxTitleLines
  }

  private emptyMedia(): Resource {
    if (this.phaseState.indexOf('deleted') >= 0) {
      return $r('app.media.delete')
    }
    if (this.phaseState.indexOf('archived') >= 0) {
      return $r('app.media.archive')
    }
    return $r('app.media.notebook')
  }

  private isSelectedCard(note: NoteCard): boolean {
    return this.isActionMode() && this.selectedNoteIds.indexOf(note.id) >= 0
  }

  private drawerIcon(row: string): Resource {
    if (row === 'Labels') {
      return $r('app.media.label')
    }
    if (row === 'Deleted') {
      return $r('app.media.delete')
    }
    if (row === 'Archived') {
      return $r('app.media.archive')
    }
    if (row === 'Settings') {
      return $r('app.media.settings')
    }
    return $r('app.media.home')
  }

  private drawerSelected(row: string): boolean {
    if (row === 'Labels') {
      return this.isLabels()
    }
    if (row === 'Deleted') {
      return this.phaseState.indexOf('deleted') >= 0
    }
    if (row === 'Archived') {
      return this.phaseState.indexOf('archived') >= 0
    }
    if (row === 'Settings') {
      return this.isSettings()
    }
    return this.currentFolder() === 'notes' && !this.isLabels() && !this.isSettings()
  }

  private noteKey(note: NoteCard): string {
    if (note.id === 'groceries' || note.title === 'Groceries' || note.title === 'Sample Checklist') {
      return 'note_card_groceries'
    }
    if (note.id === 'density') {
      return 'note_card_density'
    }
    return 'note_card_alpha'
  }

  private noteColorKey(note: NoteCard): string {
    let token = 'custom'
    if (note.color === '#FFFFFF') {
      token = 'default'
    } else if (note.color === '#FFF59D') {
      token = 'yellow'
    } else if (note.color === '#90CAF9') {
      token = 'blue'
    }
    return this.noteKey(note) + '_color_' + token
  }

  private scopeKey(title: string): string {
    if (title === 'Deleted') {
      return 'search_scope_deleted'
    }
    if (title === 'Archived') {
      return 'search_scope_archived'
    }
    return 'search_scope_notes'
  }

  private actionMenuKey(title: string): string {
    if (title === 'Change color') {
      return 'action_menu_change_color'
    }
    if (title === 'Make a copy') {
      return 'action_menu_make_copy'
    }
    if (title === 'Delete forever') {
      return 'action_menu_delete_forever'
    }
    return 'action_menu_' + title.toLowerCase()
  }

  private actionMenuRows(): string[] {
    const folder = this.currentFolder()
    if (folder === 'deleted') {
      return ['Restore', 'Delete forever']
    }
    if (folder === 'archived') {
      return ['Unarchive', 'Delete']
    }
    return this.menuRows
  }

  private searchQuery(): string {
    if (this.searchText.length > 0) {
      return this.searchText
    }
    if (this.phaseState.indexOf('page_0023_search_alpha_results') >= 0 || this.phaseState.indexOf('page_0025_search_alpha_recapture') >= 0) {
      return 'Alpha'
    }
    if (this.phaseState.indexOf('search_deleted') >= 0 || this.phaseState.indexOf('search_archived') >= 0 ||
      this.phaseState.indexOf('search_notes_scope') >= 0) {
      return 'AlphaAlpha'
    }
    return ''
  }

  private searchShowsResult(): boolean {
    return this.searchResults().length > 0
  }

  private editorDate(): string {
    return 'Wednesday, July 1, 2026'
  }

  private editorTitle(): string {
    return this.editorTitleDraft
  }

  private editorBody(): string {
    return this.editorBodyDraft
  }

  private listItemText(): string {
    return this.editorItemDraft
  }

  private labelDialogText(): string {
    if (this.labelDraft.length > 0) {
      return this.labelDraft
    }
    return this.phaseState.indexOf('filled') >= 0 ? 'Work' : ''
  }

  private settingsDialogTitle(): string {
    if (this.activeDialog === 'theme') {
      return 'Theme'
    }
    if (this.activeDialog === 'date_format') {
      return 'Date format'
    }
    if (this.activeDialog === 'text_size') {
      return 'Text size'
    }
    return 'View'
  }

  private settingsChoiceToken(title: string): string {
    if (title === 'Follow system') {
      return 'follow_system'
    }
    if (title === 'Jul 1, 2026') {
      return 'jul_1_2026'
    }
    return title.toLowerCase()
  }

  private isDrawer(): boolean {
    return this.phaseState.indexOf('drawer') >= 0
  }

  private isSettings(): boolean {
    return this.phaseState.indexOf('settings') >= 0
  }

  private isLabels(): boolean {
    return this.phaseState.indexOf('labels') >= 0 || this.phaseState.indexOf('label_context') >= 0
  }

  private isLabelPicker(): boolean {
    return this.phaseState === 'page_label_picker'
  }

  private isSearch(): boolean {
    return this.isSearchState(this.phaseState)
  }

  private isEditor(): boolean {
    return this.phaseState.indexOf('take_note') >= 0 || this.phaseState.indexOf('make_list') >= 0 ||
      this.editingNoteId.length > 0
  }

  private isListEditor(): boolean {
    return this.editorKind === 'list' || this.phaseState.indexOf('make_list') >= 0
  }

  private isCheckedListState(): boolean {
    return this.phaseState.indexOf('item_checked') >= 0 || this.phaseState.indexOf('_checked') >= 0
  }

  private isActionMode(): boolean {
    return this.phaseState.indexOf('page_0035_action_mode_one_selected') >= 0 ||
      this.phaseState.indexOf('page_0037_action_mode_more_menu') >= 0
  }

  private isActionMenu(): boolean {
    return this.activeDialog === 'action_menu' || this.phaseState.indexOf('action_mode_more_menu') >= 0
  }

  private isSearchState(state: string): boolean {
    return state.indexOf('page_0022_search_initial') >= 0 ||
      state.indexOf('page_0023_search_alpha_results') >= 0 ||
      state.indexOf('page_0025_search_alpha_recapture') >= 0 ||
      state.indexOf('page_0026_search_deleted_scope') >= 0 ||
      state.indexOf('page_0027_search_archived_scope') >= 0 ||
      state.indexOf('page_0028_search_notes_scope') >= 0
  }

  private isPopulatedListEditorState(): boolean {
    return this.phaseState.indexOf('page_0018_make_list_after_add_item') >= 0 ||
      this.phaseState.indexOf('page_0019_make_list_item_text') >= 0 ||
      this.phaseState.indexOf('page_0020_make_list_item_checked') >= 0
  }

  private needsCenteredSearchEmptyState(): boolean {
    return this.phaseState.indexOf('page_0026_search_deleted_scope') >= 0 ||
      this.phaseState.indexOf('page_0027_search_archived_scope') >= 0 ||
      this.phaseState.indexOf('page_0028_search_notes_scope') >= 0
  }

  private searchScopeForState(state: string): string {
    if (state.indexOf('search_deleted_scope') >= 0) {
      return 'Deleted'
    }
    if (state.indexOf('search_archived_scope') >= 0) {
      return 'Archived'
    }
    return 'Notes'
  }

  private isNotesLike(): boolean {
    return !this.isSettings() && !this.isLabels() && !this.isSearch() && this.phaseState.indexOf('deleted') < 0 &&
      this.phaseState.indexOf('archived') < 0
  }

  private showFabs(): boolean {
    return this.isNotesLike() && !this.isEditor() && !this.isSearch() &&
      (!this.isActionMode() || this.phaseState.indexOf('page_0035_action_mode_one_selected') >= 0 ||
        this.phaseState.indexOf('page_0037_action_mode_more_menu') >= 0)
  }

  private hasWorkLabel(): boolean {
    return this.labels.indexOf('Work') >= 0 || this.phaseState.indexOf('with_work') >= 0 || this.phaseState.indexOf('context') >= 0
  }

  private isViewDialog(): boolean {
    return this.activeDialog === 'view' || this.activeDialog === 'theme' ||
      this.activeDialog === 'date_format' || this.activeDialog === 'text_size' ||
      this.phaseState.indexOf('settings_view_dialog') >= 0
  }

  private isLabelAddDialog(): boolean {
    return this.activeDialog === 'label_add' || this.phaseState.indexOf('labels_add_dialog') >= 0
  }

  private isLabelContextDialog(): boolean {
    return this.activeDialog === 'label_context' || this.phaseState.indexOf('label_context_dialog') >= 0
  }

  private isColorDialog(): boolean {
    return this.activeDialog === 'color'
  }

  private currentFolder(): string {
    if (this.isActionMode() && this.selectedNoteId.length > 0) {
      const selected = this.findNote(this.selectedNoteId)
      if (selected) {
        return selected.folder
      }
    }
    if (this.phaseState.indexOf('deleted') >= 0) {
      return 'deleted'
    }
    if (this.phaseState.indexOf('archived') >= 0) {
      return 'archived'
    }
    return 'notes'
  }

  private visibleLabels(): string[] {
    if (this.labels.length === 0 && this.hasWorkLabel()) {
      return ['Work']
    }
    return this.labels
  }

  private navigateDrawer(row: string) {
    if (row === 'Notes') {
      this.setState('page_0012_notes_empty_returned')
    } else if (row === 'Labels') {
      this.setState(this.labels.length > 0 ? 'page_0032_labels_with_work' : 'page_0002_labels_empty')
    } else if (row === 'Deleted') {
      this.setState('page_0004_deleted_empty')
    } else if (row === 'Archived') {
      this.setState('page_0006_archived_empty')
    } else {
      this.setState('page_0008_settings')
    }
    this.activeDialog = ''
  }

  private closeDrawer() {
    this.setState('page_0000_notes_initial')
  }

  private selectedCount(): number {
    return this.selectedNoteIds.length > 0 ? this.selectedNoteIds.length : (this.selectedNoteId.length > 0 ? 1 : 0)
  }

  private clearSelection() {
    this.selectedNoteId = ''
    this.selectedNoteIds = []
    this.activeDialog = ''
    this.setState('page_0036_notes_after_action_back')
  }

  private openNewEditor(list: boolean) {
    this.editingNoteId = ''
    this.editorKind = list ? 'list' : 'text'
    this.editorTitleDraft = ''
    this.editorBodyDraft = ''
    this.editorItems = []
    this.editorItemDraft = ''
    this.editorPinActive = false
    this.editingChecklistIndex = -1
    this.editingChecklistDraft = ''
    this.setState(list ? 'page_0017_make_list_new' : 'page_0014_take_note_new')
  }

  private openExistingEditor(id: string) {
    const note = this.findNote(id)
    if (!note) {
      return
    }
    this.editingNoteId = note.id
    this.editorKind = note.list ? 'list' : 'text'
    this.editorTitleDraft = note.title
    this.editorBodyDraft = note.body
    this.editorItems = this.copyItems(note.items)
    this.editorItemDraft = ''
    this.editorPinActive = false
    this.editingChecklistIndex = -1
    this.editingChecklistDraft = ''
    this.setState(note.list ? 'page_0017_make_list_new' : 'page_0015_take_note_filled')
  }

  private saveEditor() {
    const title = this.editorTitleDraft.length > 0 ? this.editorTitleDraft : (this.isListEditor() ? 'Groceries' : 'Alpha')
    if (this.isListEditor()) {
      if (this.editorItemDraft.length > 0) {
        this.editorItems = this.editorItems.concat([this.makeItem(this.editorItemDraft, false)])
        this.editorItemDraft = ''
      }
      const items = this.editorItems.length > 0 ? this.copyItems(this.editorItems) : [this.makeItem('milk', false)]
      this.upsertNote(this.makeListNote(this.editingNoteId.length > 0 ? this.editingNoteId : 'groceries', title, items, 'notes'))
      this.setState('page_0021_notes_after_list_save')
    } else {
      this.upsertNote(this.makeTextNote(this.editingNoteId.length > 0 ? this.editingNoteId : 'alpha', title, this.editorBodyDraft, 'notes'))
      this.setState('page_0016_notes_after_text_save')
    }
    this.editingNoteId = ''
  }

  private addEditorItem() {
    if (this.editorItemDraft.length > 0) {
      this.editorItems = this.editorItems.concat([this.makeItem(this.editorItemDraft, false)])
      this.editorItemDraft = ''
    }
    this.setState('page_0018_make_list_after_add_item')
  }

  private toggleEditorDraftItem() {
    if (this.editorItemDraft.length === 0 && this.editorItems.length === 0) {
      this.editorItemDraft = 'milk'
    }
    if (this.editorItems.length > 0) {
      const first = this.editorItems[0]
      this.editorItems = [this.makeItem(first.text, !first.checked)].concat(this.editorItems.slice(1))
    }
    this.setState('page_0020_make_list_item_checked')
  }

  private toggleSavedEditorItem(index: number) {
    // The public shell exposes the control; the benchmark implementation owns
    // the checked-state mutation and persistence.
  }

  private beginSavedEditorItemEdit(index: number) {
    if (index < 0 || index >= this.editorItems.length) {
      return
    }
    this.editingChecklistIndex = index
    this.editingChecklistDraft = this.editorItems[index].text
  }

  private deleteSavedEditorItem(index: number) {
    // Public action only; the benchmark implementation owns model deletion.
  }

  private closeEditorShell() {
    this.editingNoteId = ''
    this.editorPinActive = false
    this.setState('page_0000_notes_initial')
  }

  private toggleEditorPin() {
    this.editorPinActive = !this.editorPinActive
  }

  private editorPinned(): boolean {
    return this.editorPinActive
  }

  private openEditorMenu() {
    this.activeDialog = 'action_menu'
  }

  private enterSelection(id: string) {
    this.selectedNoteId = id
    this.selectedNoteIds = [id]
    this.setState('page_0035_action_mode_one_selected')
  }

  private toggleSelection(id: string) {
    const index = this.selectedNoteIds.indexOf(id)
    if (index >= 0) {
      this.selectedNoteIds = this.selectedNoteIds.slice(0, index).concat(this.selectedNoteIds.slice(index + 1))
    } else {
      this.selectedNoteIds = this.selectedNoteIds.concat([id])
    }
    this.selectedNoteId = this.selectedNoteIds.length > 0 ? this.selectedNoteIds[0] : ''
    this.setState(this.selectedNoteIds.length > 0 ? 'page_0035_action_mode_one_selected' : 'page_0036_notes_after_action_back')
  }

  private openActionMenu() {
    if (this.selectedNoteId.length === 0) {
      this.selectedNoteId = this.firstVisibleNoteId()
      this.selectedNoteIds = [this.selectedNoteId]
    }
    this.setState('page_0037_action_mode_more_menu')
  }

  private handleActionMenu(item: string) {
    const fromEditor = this.isEditor()
    this.activeDialog = ''
    const id = this.selectedNoteId.length > 0 ? this.selectedNoteId : this.firstVisibleNoteId()
    if (item === 'Archive') {
      this.moveNote(id, 'archived')
      this.selectedNoteId = ''
      this.selectedNoteIds = []
      this.setState('page_0038_notes_after_archive_action')
    } else if (item === 'Delete') {
      this.moveNote(id, 'deleted')
      this.selectedNoteId = ''
      this.selectedNoteIds = []
      this.setState('page_0004_deleted_empty')
    } else if (item === 'Make a copy') {
      this.copyNote(id)
      this.selectedNoteId = ''
      this.selectedNoteIds = []
      this.setState('page_0036_notes_after_action_back')
    } else if (item === 'Change color') {
      this.activeDialog = 'color'
      this.setState('page_0035_action_mode_one_selected')
    } else if (item === 'Labels') {
      this.openLabelPicker(fromEditor ? 'editor' : 'selection')
    } else if (item === 'Delete forever' || item === 'Restore') {
      this.setState('page_0004_deleted_empty')
    } else if (item === 'Unarchive') {
      this.setState('page_0006_archived_empty')
    } else {
      this.setState('page_0036_notes_after_action_back')
    }
  }

  private toggleSelectedPin() {
    const id = this.selectedNoteId.length > 0 ? this.selectedNoteId : this.firstVisibleNoteId()
    this.toggleNotePinned(id)
    this.setState('page_0035_action_mode_one_selected')
  }

  private applySelectedColor(color: string) {
    const ids = this.selectedNoteIds.length > 0 ? this.selectedNoteIds : [this.selectedNoteId.length > 0 ? this.selectedNoteId : this.firstVisibleNoteId()]
    ids.forEach((id: string) => {
      this.setNoteColor(id, color)
    })
    this.activeDialog = ''
    this.setState('page_0035_action_mode_one_selected')
  }

  private deleteAllDeleted() {
    this.setState('page_0004_deleted_empty')
  }

  private openDialog(name: string) {
    this.activeDialog = name
    if (name === 'view') {
      this.setState('page_0009_settings_view_dialog')
    }
  }

  private closeDialog() {
    this.activeDialog = ''
    this.setState('page_0008_settings')
  }

  private openLabelPicker(origin: string) {
    this.labelPickerOrigin = origin
    this.labelPickerReturnState = origin === 'editor'
      ? this.phaseState : 'page_0035_action_mode_one_selected'
    this.activeDialog = ''
    this.setState('page_label_picker')
  }

  private closeLabelPicker() {
    const target = this.labelPickerReturnState.length > 0
      ? this.labelPickerReturnState : 'page_0036_notes_after_action_back'
    this.labelPickerOrigin = ''
    this.labelPickerReturnState = ''
    this.activeDialog = ''
    this.setState(target)
  }

  private pickerNoteId(): string {
    if (this.labelPickerOrigin === 'editor' && this.editingNoteId.length > 0) {
      return this.editingNoteId
    }
    return this.selectedNoteId.length > 0 ? this.selectedNoteId : this.firstVisibleNoteId()
  }

  private pickerNoteHasLabel(label: string): boolean {
    const note: NoteCard | undefined = this.findNote(this.pickerNoteId())
    return note !== undefined && note.labels.indexOf(label) >= 0
  }

  private openLabelAddDialog() {
    this.labelDialogOrigin = this.isLabelPicker() ? 'picker' : 'labels'
    this.activeDialog = 'label_add'
    if (this.labelDialogOrigin !== 'picker') {
      this.setState('page_0031_labels_add_dialog')
    }
  }

  private cancelLabelDialog() {
    this.activeDialog = ''
    this.labelDraft = ''
    if (this.labelDialogOrigin === 'picker') {
      this.labelDialogOrigin = ''
      this.setState('page_label_picker')
    } else {
      this.labelDialogOrigin = ''
      this.setState('page_0030_labels_empty_after_clear')
    }
  }

  private saveLabelDialog() {
    const name = this.labelDraft.length > 0 ? this.labelDraft : (this.labelName.length > 0 ? this.labelName : 'Work')
    this.insertLabel(name)
    this.activeDialog = ''
    this.labelDraft = ''
    if (this.labelDialogOrigin === 'picker') {
      this.labelDialogOrigin = ''
      this.setState('page_label_picker')
    } else {
      this.labelDialogOrigin = ''
      this.setState('page_0002_labels_empty')
    }
  }

  private openLabelNotes(label: string) {
    this.searchText = label
    this.searchScope = 'Notes'
    this.setState('page_0028_search_notes_scope')
  }

  private openLabelContext(label: string) {
    this.labelName = label
    this.labelDraft = label
    this.activeDialog = 'label_context'
    this.setState('page_0033_label_context_dialog')
  }

  private handleLabelContext(title: string) {
    this.activeDialog = ''
    if (title === 'Delete') {
      this.deleteLabel(this.labelName.length > 0 ? this.labelName : 'Work')
      this.setState('page_0030_labels_empty_after_clear')
    } else {
      this.activeDialog = 'label_add'
      this.setState('page_0042_labels_add_dialog_filled')
    }
  }

  private closeSearch() {
    this.searchText = ''
    this.searchScope = 'Notes'
    this.setState('page_0024_notes_after_search_back')
  }

  private searchResults(): NoteCard[] {
    return []
  }

  private findNote(id: string): NoteCard | undefined {
    for (let i = 0; i < this.notes.length; i++) {
      if (this.notes[i].id === id) {
        return this.notes[i]
      }
    }
    return undefined
  }

  private upsertNote(next: NoteCard) {
    return
  }

  private moveNote(id: string, folder: string) {
    return
  }

  private copyNote(id: string) {
    return
  }

  private setNoteColor(id: string, color: string) {
    return
  }

  private toggleNotePinned(id: string) {
    return
  }

  private assignSelectedLabel(id: string) {
    return
  }

  private togglePickerLabel(id: string, label: string) {
    return
  }

  private insertLabel(name: string) {
    return
  }

  private deleteLabel(name: string) {
    return
  }

  private firstVisibleNoteId(): string {
    const cards = this.noteCards()
    return cards.length > 0 ? cards[0].id : ''
  }

  private copyItems(items: ChecklistItem[]): ChecklistItem[] {
    let copy: ChecklistItem[] = []
    items.forEach((item: ChecklistItem) => {
      copy = copy.concat([this.makeItem(item.text, item.checked)])
    })
    return copy
  }

  private cloneNoteWith(note: NoteCard, folder: string, color: string, pinned: boolean, labels: string[]): NoteCard {
    return {
      id: note.id,
      title: note.title,
      time: note.time,
      body: note.body,
      color: color,
      list: note.list,
      folder: folder,
      pinned: pinned,
      labels: labels.slice(),
      items: this.copyItems(note.items)
    }
  }

}
