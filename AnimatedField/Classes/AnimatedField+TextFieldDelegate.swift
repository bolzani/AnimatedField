//
//  AnimatedField+Delegate.swift
//  FashTime
//
//  Created by Alberto Aznar de los Ríos on 03/04/2019.
//  Copyright © 2019 FashTime Ltd. All rights reserved.
//

import Foundation

extension String {
    
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }
    
    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
}


extension AnimatedField: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Priorize datasource returns
        if let shouldChange = dataSource?.animatedField(self, shouldChangeCharactersIn: range, replacementString: string) {
            return shouldChange
        }
        if let format = type.format {
            
            if case AnimatedFieldType.phone = type {
                let oldClean = textField.text!.removeCharacters(from: "() -")
                let newClean = textField.text!.replacingCharacters(in: range, with: string).removeCharacters(from: "() -")
                
                if oldClean.count <= 10 && newClean.count <= 10 {
                    let formatter = DefaultTextInputFormatter(textPattern: "(##) ####-####")
                    let result = formatter.formatInput(currentText: textField.text ?? "", range: range, replacementString: string)
                    textField.text = result.formattedText
                    textField.setCursorLocation(result.caretBeginOffset)
                    return false
                } else if oldClean.count <= 10 && newClean.count > 10 {
                    let formatter = DefaultTextInputFormatter(textPattern: "(##) #####-####")
                    textField.text = formatter.format(newClean)
                    return false
                } else if oldClean.count > 10 && newClean.count <= 10 {
                    let formatter = DefaultTextInputFormatter(textPattern: "(##) ####-####")
                    textField.text = formatter.format(newClean)
                    return false
                } else if oldClean.count > 10 && newClean.count > 10 {
                    let formatter = DefaultTextInputFormatter(textPattern: "(##) #####-####")
                    let result = formatter.formatInput(currentText: textField.text ?? "", range: range, replacementString: string)
                    textField.text = result.formattedText
                    textField.setCursorLocation(result.caretBeginOffset)
                    return false
                }
                
            }
            
            let formatter = DefaultTextInputFormatter(textPattern: format)
            let result = formatter.formatInput(currentText: textField.text ?? "", range: range, replacementString: string)
            textField.text = result.formattedText
            textField.setCursorLocation(result.caretBeginOffset)
            return false
        }
        
        // Copy new character
        var newInput = string
        
        // Replace special characters in newInput
        newInput = newInput.replacingOccurrences(of: "`", with: "")
        newInput = newInput.replacingOccurrences(of: "^", with: "")
        newInput = newInput.replacingOccurrences(of: "¨", with: "")
        
        // Replace special characters in textField
        textField.text = textField.text?.replacingOccurrences(of: "`", with: "")
        textField.text = textField.text?.replacingOccurrences(of: "^", with: "")
        textField.text = textField.text?.replacingOccurrences(of: "¨", with: "")
        
        // Apply uppercased & lowercased if available
        if uppercased { newInput = newInput.uppercased() }
        if lowercased { newInput = newInput.lowercased() }
        
        // Limits & Regular expressions
        let limit = dataSource?.animatedFieldLimit(self) ?? Int.max
        let typingExpression = type.typingExpression
        let regex = dataSource?.animatedFieldTypingMatches(self) ?? typingExpression
        
        // Check regular expression
        if !newInput.isValidWithRegEx(regex) && newInput != "" { return false }
        
        // Change textfield in manual mode in case of changing newInput. Check limits also
        if newInput != string {
            textField.text = textField.text?.count ?? 0 + newInput.count <= limit ? "\(textField.text ?? "")\(newInput)" : textField.text
            return false
        }
        
        // Check price (if case)
        if newInput != "", case let AnimatedFieldType.price(maxPrice, maxDecimals) = type {
            
            let newText = "\(textField.text ?? "")\(newInput)"
        
            if let price = formatter.number(from: newText) {
                let components = newText.components(separatedBy: Locale.current.decimalSeparator ?? ".")
                if components.count > 1 {
                    if components[1].count > maxDecimals {
                        return false
                    }
                }
                if price.doubleValue > maxPrice {
                    // return false
                }
            }
        }
        
        if newInput == "" { return true }
        
        // Check limits
        return textField.text?.count ?? 0 + newInput.count < limit
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return dataSource?.animatedFieldShouldReturn(self) ?? true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
//        if !format.titleAlwaysVisible { animateIn() }
        animateIn()
        hideAlert()
        highlightField(true)
        delegate?.animatedFieldDidBeginEditing(self)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
//        if !format.titleAlwaysVisible { animateOut() }
        animateOut()
        highlightField(false)
        delegate?.animatedFieldDidEndEditing(self)
        
        if let error = validateText(textField.text) {
            showAlert(error)
            delegate?.animatedField(self, didShowAlertMessage: error)
        }
    }
}

private extension UITextField {
    
    func setCursorLocation(_ location: Int) {
        if let cursorLocation = position(from: beginningOfDocument, offset: location) {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.selectedTextRange = strongSelf.textRange(from: cursorLocation, to: cursorLocation)
            }
        }
    }
}
