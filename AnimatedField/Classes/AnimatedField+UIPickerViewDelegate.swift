//
//  AnimatedField+UIPickerViewDelegate.swift
//  AnimatedField
//
//  Created by Alberto Aznar de los Ríos on 12/04/2019.
//

import Foundation

extension AnimatedField: UIPickerViewDataSource, UIPickerViewDelegate {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if case let AnimatedFieldType.custompicker(options, _) = type {
            return options.count
        } else {
            return numberOptions.count
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if case let AnimatedFieldType.custompicker(options, _) = type {
            return options[row]
        } else {
            return "\(numberOptions[row])"
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if case let AnimatedFieldType.custompicker(options, _) = type {
            delegate?.animatedField(self, didChangePickerValue: options[row])
        } else {
            delegate?.animatedField(self, didChangePickerValue: "\(numberOptions[row])")
        }
    }
}
