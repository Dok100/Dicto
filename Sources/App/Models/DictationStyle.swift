enum DictationStyle: String, CaseIterable {
    case neutral, formal, casual, empathic

    var label: String {
        switch self {
        case .neutral:  return "Neutral"
        case .formal:   return "Formell"
        case .casual:   return "Locker"
        case .empathic: return "Empathisch"
        }
    }

    var promptSuffix: String {
        switch self {
        case .neutral:  return ""
        case .formal:   return "Formuliere den Text in einem formellen, professionellen Stil."
        case .casual:   return "Formuliere den Text in einem lockeren, freundlichen Stil."
        case .empathic: return "Formuliere den Text in einem empathischen, einfühlsamen Stil."
        }
    }
}
