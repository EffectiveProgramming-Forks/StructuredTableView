//
//  PrimaryColorDataSource.swift
//
//  Copyright © 2018 Purgatory Design. Licensed under the MIT License.
//

import UIKit

class PrimaryColorDataSource: StructuredTableDataSource {

	let colors = ["red": UIColor.red, "green": UIColor.green, "blue": UIColor.blue,
				  "cyan": UIColor.cyan, "magenta": UIColor.magenta, "yellow": UIColor.yellow]

	deinit {
		print("PrimaryColorDataSource.deinit")
	}

	init() {
		super.init(Section.self)

		self.register(self, configuration: PrimaryColorDataSource.configureLabelCell)
		self.register(reuseIdentifier: "label", for: Section.sections.flatMap({ $0.rows }))
	}

	func configureLabelCell(cell: LabelTableViewCell, forRowAt tableIndex: TableIndex) {
		let identifier = tableIndex.row.identifier
		cell.label.text = identifier.capitalized
		cell.label.textColor = (tableIndex == TableIndex(row: Section.Subtractive.yellow, section: Section.subtractive)) ? .darkGray : .white
		cell.contentView.backgroundColor = self.colors[identifier] ?? .white
	}

	enum Section: Int, TableSectionBase {
		case additive, subtractive

		enum Additive: Int, TableRowBase {
			case red, green, blue
		}

		enum Subtractive: Int, TableRowBase {
			case cyan, magenta, yellow
		}

		var rows: [TableRow] {
			switch self {
				case .additive: return Additive.rows
				case .subtractive: return Subtractive.rows
			}
		}
	}
}
