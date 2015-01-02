//
//  ExpressionParser.swift
//  GRMustache
//
//  Created by Gwendal Roué on 25/10/2014.
//  Copyright (c) 2014 Gwendal Roué. All rights reserved.
//

class ExpressionParser {
    
    func parse(string: String, inout empty outEmpty: Bool, error: NSErrorPointer) -> Expression? {
        
        enum State {
            case Error(String)
            case Initial
            case LeadingDot
            case Identifier(start: String.Index)
            case WaitingForIdentifier
            case IdentifierDone
            case FilterDone
            case Empty
            case Valid(expression: Expression)
        }
        
        var state: State = .Initial
        var filterExpressionStack: [Expression] = []
        var currentExpression: Expression?
        
        var i = string.startIndex
        let end = string.endIndex
        stringLoop: while i < end {
            let c = string[i]
            
            switch state {
            case .Error:
                break stringLoop
            case .Initial:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    break
                case ".":
                    state = .LeadingDot
                    currentExpression = ImplicitIteratorExpression()
                case "(":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case ")":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case ",":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case "{", "}", "&", "$", "#", "^", "/", "<", ">":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                default:
                    state = .Identifier(start: i)
                }
            case .LeadingDot:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    state = .IdentifierDone
                case ".":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case "(":
                    state = .Initial
                    filterExpressionStack.append(currentExpression!)
                    currentExpression = nil
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        state = .FilterDone
                        filterExpressionStack.removeLast()
                        currentExpression = FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: false)
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        state = .Initial
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: true))
                        currentExpression = nil
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                case "{", "}", "&", "$", "#", "^", "/", "<", ">":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                default:
                    state = .Identifier(start: i)
                }
            case .Identifier(start: let identifierStart):
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    let identifier = string.substringWithRange(identifierStart..<i)
                    if currentExpression != nil {
                        currentExpression = ScopedExpression(baseExpression:currentExpression!, identifier: identifier)
                    } else {
                        currentExpression = IdentifierExpression(identifier: identifier)
                    }
                    state = .IdentifierDone
                case ".":
                    let identifier = string.substringWithRange(identifierStart..<i)
                    if currentExpression != nil {
                        currentExpression = ScopedExpression(baseExpression:currentExpression!, identifier: identifier)
                    } else {
                        currentExpression = IdentifierExpression(identifier: identifier)
                    }
                    state = .WaitingForIdentifier
                case "(":
                    let identifier = string.substringWithRange(identifierStart..<i)
                    if currentExpression != nil {
                        currentExpression = ScopedExpression(baseExpression:currentExpression!, identifier: identifier)
                    } else {
                        currentExpression = IdentifierExpression(identifier: identifier)
                    }
                    state = .Initial
                    filterExpressionStack.append(currentExpression!)
                    currentExpression = nil
                case ")":
                    let identifier = string.substringWithRange(identifierStart..<i)
                    if currentExpression != nil {
                        currentExpression = ScopedExpression(baseExpression:currentExpression!, identifier: identifier)
                    } else {
                        currentExpression = IdentifierExpression(identifier: identifier)
                    }
                    if let filterExpression = filterExpressionStack.last {
                        state = .FilterDone
                        filterExpressionStack.removeLast()
                        currentExpression = FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: false)
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                case ",":
                    let identifier = string.substringWithRange(identifierStart..<i)
                    if currentExpression != nil {
                        currentExpression = ScopedExpression(baseExpression:currentExpression!, identifier: identifier)
                    } else {
                        currentExpression = IdentifierExpression(identifier: identifier)
                    }
                    if let filterExpression = filterExpressionStack.last {
                        state = .Initial
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: true))
                        currentExpression = nil
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                default:
                    break
                }
            case .WaitingForIdentifier:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    state = .Error("Unexpected white space character at index \(distance(string.startIndex, i))")
                case ".":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case "(":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case ")":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case ",":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case "{", "}", "&", "$", "#", "^", "/", "<", ">":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                default:
                    state = .Identifier(start: i)
                }
            case .IdentifierDone:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    break
                case ".":
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                case "(":
                    state = .Initial
                    filterExpressionStack.append(currentExpression!)
                    currentExpression = nil
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        state = .FilterDone
                        filterExpressionStack.removeLast()
                        currentExpression = FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: false)
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        state = .Initial
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: true))
                        currentExpression = nil
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                default:
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                }
            case .FilterDone:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    break
                case ".":
                    state = .WaitingForIdentifier
                case "(":
                    state = .Initial
                    filterExpressionStack.append(currentExpression!)
                    currentExpression = nil
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        state = .FilterDone
                        filterExpressionStack.removeLast()
                        currentExpression = FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: false)
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        state = .Initial
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(FilteredExpression(filterExpression: filterExpression, argumentExpression: currentExpression!, partialApplication: true))
                        currentExpression = nil
                    } else {
                        state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                    }
                default:
                    state = .Error("Unexpected character `\(c)` at index \(distance(string.startIndex, i))")
                }
            default:
                fatalError("Unexpected state")
            }
            
            i = i.successor()
        }
        
        switch state {
        case .Initial:
            if filterExpressionStack.isEmpty {
                state = .Empty
            } else {
                state = .Error("Missing `)` character at index \(distance(string.startIndex, string.endIndex))")
            }
        case .LeadingDot:
            if filterExpressionStack.isEmpty {
                state = .Valid(expression: currentExpression!)
            } else {
                state = .Error("Missing `)` character at index \(distance(string.startIndex, string.endIndex))")
            }
        case .Identifier(start: let identifierStart):
            let identifier = string.substringFromIndex(identifierStart)
            if currentExpression != nil {
                currentExpression = ScopedExpression(baseExpression:currentExpression!, identifier: identifier)
            } else {
                currentExpression = IdentifierExpression(identifier: identifier)
            }
            if filterExpressionStack.isEmpty {
                state = .Valid(expression: currentExpression!)
            } else {
                state = .Error("Missing `)` character at index \(distance(string.startIndex, string.endIndex))")
            }
        case .WaitingForIdentifier:
            state = .Error("Missing identifier at index \(distance(string.startIndex, string.endIndex))")
        case .IdentifierDone:
            if filterExpressionStack.isEmpty {
                state = .Valid(expression: currentExpression!)
            } else {
                state = .Error("Missing `)` character at index \(distance(string.startIndex, string.endIndex))")
            }
        case .FilterDone:
            if filterExpressionStack.isEmpty {
                state = .Valid(expression: currentExpression!)
            } else {
                state = .Error("Missing `)` character at index \(distance(string.startIndex, string.endIndex))")
            }
        case .Error:
            break
        default:
            fatalError("Unexpected state")
        }
        
        // End
        
        switch state {
        case .Empty:
            outEmpty = true
            if error != nil {
                error.memory = NSError(domain: GRMustacheErrorDomain, code: GRMustacheErrorCodeParseError, userInfo: [NSLocalizedDescriptionKey: "Missing expression"])
            }
            return nil
        case .Error(let description):
            outEmpty = false
            if error != nil {
                error.memory = NSError(domain: GRMustacheErrorDomain, code: GRMustacheErrorCodeParseError, userInfo: [NSLocalizedDescriptionKey: "Invalid expression `\(string)`: \(description)"])
            }
            return nil
        case .Valid(expression: let validExpression):
            return validExpression
        default:
            fatalError("Unexpected state")
        }
        
        return nil
    }
}
