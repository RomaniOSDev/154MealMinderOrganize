import UIKit

enum UIKitTableChromeBootstrap {
    private static var didApply = false

    static func applyOnce() {
        guard didApply == false else { return }
        didApply = true

        guard let canvas = UIColor(named: "AppBackground"),
              let grouping = UIColor(named: "AppSurface") else {
            return
        }

        UITableView.appearance().backgroundColor = canvas
        UITableView.appearance().separatorColor = grouping.withAlphaComponent(0.45)
        UITableViewCell.appearance().backgroundColor = .clear
    }
}
