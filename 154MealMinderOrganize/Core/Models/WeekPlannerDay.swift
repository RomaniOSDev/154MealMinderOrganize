import Foundation

enum WeekPlannerDay: String, CaseIterable, Identifiable, Codable {
    case mon, tue, wed, thu, fri, sat, sun

    var id: String { rawValue }

    /// Weekday label (English, localised by system region if needed).
    var shortTitle: String {
        switch self {
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        case .sun: return "Sun"
        }
    }

    /// Gregorian weekday (Sun–Sat) → planner day keys used in persisted assignments.
    static func today(reference: Date = Date(), calendar: Calendar = .current) -> WeekPlannerDay {
        let weekday = calendar.component(.weekday, from: reference)
        switch weekday {
        case 1: return .sun
        case 2: return .mon
        case 3: return .tue
        case 4: return .wed
        case 5: return .thu
        case 6: return .fri
        case 7: return .sat
        default: return .mon
        }
    }
}
