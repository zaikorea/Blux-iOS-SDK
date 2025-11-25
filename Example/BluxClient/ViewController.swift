//
//  ViewController.swift
//  Blux
//

import BluxClient
import UIKit

class ViewController: UIViewController {
    let userId = "luna"

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func SignIn(_: Any) {
        BluxClient.signIn(userId: userId)
    }

    @IBAction func SignOut(_: Any) {
        BluxClient.signOut()
    }

    @IBAction func SetUserProperties(_: Any) {
        BluxClient.setUserProperties(userProperties: UserProperties(phoneNumber: "01089200854", emailAddress: "luna@blux.ai"))
    }

    @IBAction func SetCustomUserProperties(_: Any) {
        do {
            let customProperties: [String: Any] = [
                "phone_number": "01089200854",
                "email_address": "luna@blux.ai",
                "age": 30,
                "is_active": true,
                "height": 5.9,
                "hobbies": ["reading", "gaming"],
            ]
            try BluxClient.setCustomUserProperties(customUserProperties: customProperties)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func SendPDVEvent1(_: Any) {
        do {
            let eventRequest = try AddProductDetailViewEvent.Builder(itemId: "test_item_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func SendPDVEvent2(_: Any) {
        do {
            let eventRequest = try AddCustomEvent.Builder(eventType: "test_event_custom")
                .addItem(id: "test_item", price: 10, quantity: 1)
                .orderAmount(2000)
                .paidAmount(3000)
                .orderId("test_order_id")
                .customEventProperties(["test_custom": .stringArray(["a"]), "test_custom_2": .string("2025-06-16T12:34:56Z")])
                .build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func SendPDVEvent3(_: Any) {
        do {
            let eventRequest = try AddOrderEvent.Builder()
                .addItem(id: "test_item_1", price: 1000, quantity: 1)
                .addItem(id: "test_item_2", price: 2000, quantity: 2)
                .orderAmount(12000)
                .paidAmount(20000)
                .orderId("test_order_id")
                .customEventProperties(["coupons": .stringArray(["a", "b"])])
                .build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func SendLikeEvent(_: Any) {
        do {
            let eventRequest = try AddLikeEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func SendCartaddEvent(_: Any) {
        do {
            let eventRequest = try AddCartaddEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendEvent(eventRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
