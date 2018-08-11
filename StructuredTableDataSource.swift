//
//  StructuredTableDataSource.swift
//
//  Copyright © 2018 Purgatory Design. Licensed under the MIT License.
//

import UIKit


//protocol CaseIterableEnum {
//	associatedtype AllCases: Collection where Self.AllCases.Element == Self
//	static var allCases: Self.AllCases { get }
//}

public struct TableIndex {
	let row: TableRow
	let section: TableSection

	var indexPath: IndexPath { return IndexPath(item: self.row.index, section: self.section.index) }
}

extension TableIndex: Equatable {
	public static func == (lhs: TableIndex, rhs: TableIndex) -> Bool {
		return (lhs.row.index == rhs.row.index) && (lhs.section.index == rhs.section.index)
	}
}

public protocol TableSection {
	var index: Int { get }
	var rawValue: Int { get }
	var name: String { get }
	var title: String { get }
	var rows: [TableRow] { get }
	var showHeaderTitle: Bool { get }
	var showFooterTitle: Bool { get }
	static var sections: [TableSection] { get }
	static func tableIndex(_ indexPath: IndexPath) -> TableIndex
}

extension TableSection {
	var index: Int { return self.rawValue }
	var name: String { return "\(self)" }
	var title: String { return "\(self)".capitalized }
	var showHeaderTitle: Bool { return Self.sections.count > 1 }
	var showFooterTitle: Bool { return false }
}

public protocol TableSectionBase: TableSection, CaseIterable, Equatable {}

extension TableSectionBase {
	static var sections: [TableSection] { return Array(Self.allCases) }

	static func tableIndex(_ indexPath: IndexPath) -> TableIndex {
		let section = Self.sections[indexPath.section]
		let row = section.rows[indexPath.row]
		return TableIndex(row: row, section: section)
	}
}

public protocol TableRow {
	var index: Int { get }
	var rawValue: Int { get }
	var name: String { get }
	var identifier: String { get }
	static var rows: [TableRow] { get }
}

extension TableRow {
	var index: Int { return self.rawValue }
	var name: String { return "\(self)" }
	var identifier: String { return "\(self)" }
}

public protocol TableRowBase: TableRow, CaseIterable {}

extension TableRowBase {
	static var rows: [TableRow] { return Array(Self.allCases) }
}

private protocol CellConfiguration {
	func configure(_ cell: UITableViewCell, _ tableIndex: TableIndex)
}

public class StructuredTableDataSource: NSObject {
	public let structure: TableSection.Type

	private typealias ConfigurationFunction = (AnyObject) -> (UITableViewCell, TableIndex) -> Void

	private struct CellConfigurationKey: Hashable {
		let type: ObjectIdentifier
		let identifier: String
	}

	private struct CellConfigurationWrapper<Target: AnyObject>: CellConfiguration {
		weak var target: Target?
		let action: ConfigurationFunction

		func configure(_ cell: UITableViewCell, _ tableIndex: TableIndex) {
			if let target = self.target {
				self.action(target)(cell, tableIndex)
			}
		}
	}

	private var configurationRegistry: [CellConfigurationKey: CellConfiguration] = [:]
	private var reuseIdentifierRegistry: [String: String] = [:]

	public init(_ structure: TableSection.Type) {
		self.structure = structure
	}

	public func register<Target, Cell>(_ target: Target, configuration: @escaping (Target) -> (Cell, TableIndex) -> Void, for row: TableRow? = nil) where Target: AnyObject, Cell: UITableViewCell {
		let key = CellConfigurationKey(type: ObjectIdentifier(Cell.self), identifier: row?.identifier ?? "")
		let value = CellConfigurationWrapper(target: target, action: unsafeBitCast(configuration, to: ConfigurationFunction.self))
		self.configurationRegistry[key] = value
	}

	public func register<Target, Cell>(_ target: Target, configuration: @escaping (Target) -> (Cell, TableIndex) -> Void, for rows: [TableRow]) where Target: AnyObject, Cell: UITableViewCell {
		for row in rows {
			self.register(target, configuration: configuration, for: row)
		}
	}

	public func unregister<Cell>(configuration: @escaping (Cell, TableIndex) -> Void, for row: TableRow? = nil) where Cell: UITableViewCell {
		let key = CellConfigurationKey(type: ObjectIdentifier(Cell.self), identifier: row?.identifier ?? "")
		self.configurationRegistry[key] = nil
	}

	public func register(reuseIdentifier: String, for row: TableRow) {
		self.reuseIdentifierRegistry[row.identifier] = reuseIdentifier
	}

	public func register(reuseIdentifier: String, for rows: [TableRow]) {
		for row in rows {
			self.register(reuseIdentifier: reuseIdentifier, for: row)
		}
	}

	public func unregisterReuseIdentifier(for row: TableRow) {
		self.reuseIdentifierRegistry[row.identifier] = nil
	}

	public func unregister() {
		self.configurationRegistry = [:]
		self.reuseIdentifierRegistry = [:]
	}

	public func configure(cell: UITableViewCell, forRowAt tableIndex: TableIndex) {
		let key = CellConfigurationKey(type: ObjectIdentifier(type(of: cell)), identifier: tableIndex.row.identifier)
		if let cellConfiguration = self.configurationRegistry[key] {
			cellConfiguration.configure(cell, tableIndex)
		} else {
			let defaultKey = CellConfigurationKey(type: ObjectIdentifier(type(of: cell)), identifier: "")
			if let cellConfiguration = self.configurationRegistry[defaultKey] {
				cellConfiguration.configure(cell, tableIndex)
			}
		}
	}
}

extension StructuredTableDataSource: UITableViewDataSource {
	public func numberOfSections(in tableView: UITableView) -> Int {
		return self.structure.sections.count
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection index: Int) -> Int {
		return self.structure.sections[index].rows.count
	}

	public func tableView(_ tableView: UITableView, titleForHeaderInSection index: Int) -> String? {
		let section = self.structure.sections[index]
		return section.showHeaderTitle ? section.title : nil
	}

	public func tableView(_ tableView: UITableView, titleForFooterInSection index: Int) -> String? {
		let section = self.structure.sections[index]
		return section.showFooterTitle ? section.title : nil
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let tableIndex = self.structure.tableIndex(indexPath)
		let identifier = self.reuseIdentifierRegistry[tableIndex.row.identifier] ?? tableIndex.row.identifier
		let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
		self.configure(cell: cell, forRowAt: tableIndex)
		return cell
	}
}
