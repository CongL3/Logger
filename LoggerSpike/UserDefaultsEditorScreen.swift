//
//  UserDefaultsEditorScreen.swift
//  LoggerSpike
//
//  Created by Cong Le on 24/08/2024.
//

import SwiftUI

class UserDefaultsManager: ObservableObject {
    @Published var items: [UserDefaultsItem] = []
    
    private let systemKeys: Set<String> = [
        "PKLogNotificationServiceResponsesKey",
        "AppleLanguagesSchemaVersion",
        "AppleKeyboardsExpanded",
        "AKLastIDMSEnvironment",
        "NSHyphenatesAsLastResort",
        "ApplePasscodeKeyboards",
        "AKLastLocale",
        "AppleLocale",
        "NSUsesCFStringTokenizerForLineBreaks",
        "AddingEmojiKeybordHandled",
        "NSUsesTextStylesForLineBreaks",
        "NSVisualBidiSelectionEnabled",
        "AppleKeyboards",
        "NSLanguages",
        "NSInterfaceStyle",
        "AppleLanguages"
    ]
    
    init() {
        loadItems()
    }
    
    func loadItems() {
        
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let filteredKeys = allKeys.filter { !systemKeys.contains($0) }
        
        items = filteredKeys.map { key in
            UserDefaultsItem(key: key, value: defaults.object(forKey: key) ?? "nil")
        }
    }
    
    func updateItem(_ item: UserDefaultsItem) {
        if let index = items.firstIndex(where: { $0.key == item.key }) {
            items[index] = item
        } else {
            items.append(item)
        }
        UserDefaults.standard.set(item.value, forKey: item.key)
    }

    func clearAll() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        loadItems()
    }

    func populateSampleData() {
        UserDefaults.standard.set("Sample String", forKey: "SampleString")
        UserDefaults.standard.set(42, forKey: "SampleInt")
        UserDefaults.standard.set(true, forKey: "SampleBool")
        UserDefaults.standard.set(Date(), forKey: "SampleDate")
        UserDefaults.standard.set(["Item 1", "Item 2"], forKey: "SampleArray")
        loadItems()
    }
}

struct UserDefaultsItem: Identifiable {
    let id = UUID()
    let key: String
    var value: Any
}

struct UserDefaultsEditorView: View {
    @ObservedObject private var userDefaultsManager = UserDefaultsManager()
    @State private var selectedItem: UserDefaultsItem?

    var body: some View {
        NavigationView {
            List(userDefaultsManager.items) { item in
                HStack {
                    Text(item.key)
                    Spacer()
                    Text("\(item.value)")
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = item
                }
            }
            .navigationTitle("User Defaults Editor")
            .navigationBarItems(leading: Button("Populate") {
                userDefaultsManager.populateSampleData()
            }, trailing: Button("Clear All") {
                userDefaultsManager.clearAll()
            })
            .sheet(item: $selectedItem) { item in
                UserDefaultsItemDetailView(item: item, onSave: { updatedItem in
                    userDefaultsManager.updateItem(updatedItem)
                })
            }
        }
    }
}

struct UserDefaultsItemDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var editedValue: String
    @State private var boolValue: Bool?
    @State private var dateValue: Date?
    @State private var arrayValue: [String] = []
    
    let item: UserDefaultsItem
    let onSave: (UserDefaultsItem) -> Void
    let defaults = UserDefaults.standard

    init(item: UserDefaultsItem, onSave: @escaping (UserDefaultsItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _editedValue = State(initialValue: "\(item.value)")
        if let bool = item.value as? Bool {
            _boolValue = State(initialValue: bool)
        } else if let date = item.value as? Date {
            _dateValue = State(initialValue: date)
        } else if let array = item.value as? [String] {
            _arrayValue = State(initialValue: array)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Edit Value")) {
                switch item.value {
                case is Bool:
                    Picker("Value", selection: $boolValue) {
                        Text("True").tag(true as Bool?)
                        Text("False").tag(false as Bool?)
                        Text("Nil").tag(nil as Bool?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                case is Date:
                    DatePicker("Date", selection: Binding(
                        get: { dateValue ?? Date() },
                        set: { dateValue = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                case is [String]:
                    List {
                        ForEach(arrayValue, id: \.self) { item in
                            Text(item)
                        }
                        .onDelete(perform: removeArrayItems)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                arrayValue.append("New Item")
                            }
                        }
                    }
                default:
                    TextField("Value", text: $editedValue)
                }
            }
            Section {
                Button("Save") {
                    saveValue()
                }
            }
        }
        .navigationTitle("Edit Item")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveValue() {
        var updatedItem = item
        if let boolValue = boolValue {
            updatedItem.value = boolValue
            defaults.set(boolValue, forKey: item.key)
        } else if let dateValue = dateValue {
            updatedItem.value = dateValue
            defaults.set(dateValue, forKey: item.key)
        } else if !arrayValue.isEmpty {
            updatedItem.value = arrayValue
            defaults.set(arrayValue, forKey: item.key)
        } else {
            updatedItem.value = editedValue
            defaults.set(editedValue, forKey: item.key)
        }
        onSave(updatedItem)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func removeArrayItems(at offsets: IndexSet) {
        arrayValue.remove(atOffsets: offsets)
    }
}
