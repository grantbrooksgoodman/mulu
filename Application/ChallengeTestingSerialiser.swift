//
//  ChallengeTestingSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class ChallengeTestingSerialiser
{
    //==================================================//
    
    /* Class-Level Variable Declarations */
    
    let sampleChallenges = ["Commandos": "- Up and down on both arms counts as 1 rep\n- Keep your core activated so your hips don't sway\n- Works arms, abs, and triceps",
                            "Star jumps": "- Start in a quarter squat position with feet together, back flat, and arms down touching your lower legs\n- Works quadriceps, glutes, hamstrings, calves, deltoids",
                            "Cupid shuffle": "- Learn this short fitness routine and send your best attempt to hello@getmulu.com to get your points!",
                            "Long jumps and tread backs": "- Do as many as you can in 3 minutes. Take 30 second breaks in between each minute.",
                            "Yoga tree pose": "- Hold a yoga tree pose for as long as you can, up to 90 seconds for each side\n- Make sure to put your foot on the opposite leg's thigh or calf, NOT on the knee (to prevent injury)",
                            "Bicycle crunches": "- Do as many bicycle kicks as you can in 5 minutes (45 seconds of kicks, 15 seconds of reps)",
                            "Cupid shuffle – part 2!": "- Learn this short fitness routine and send your best attempt to hello@getmulu.com to get your points!",
                            "High knees": "- Do 200 high knees (each knee counts as 1)\n- Run in place; keep your hands in front of you above hip level and tap your knee on each step or pump your arms at your sides\n- Works quads, glutes, calves, shins",
                            "Cross punches": "- Complete 5 minutes of cross punches (45 seconds of alternating punches; 15 seconds of rest)\n- Stand with your abs tight, back flat, and loose bend in your knees. Keep your core tight throughout.",
                            "Side planks": "- Hold a side plank for as long as you can up to 2 minutes on each side. Do the full 2 minutes on one side before switching if you want to challenge yourself, or alternate between left and right sides each minute.",
                            "Squat jumps": "- Do 50 squat jumps. Make sure to take your time and pay special attention to your form to avoid injury!\n- As you jump, fully extend your legs and push your arms down. Land lightly on toes and immediately drop into a squat again.\n- Holding your hands behind your head is optional - some people find it helps with posture",
                            "Galantis x Ab ": "- Learn this short fitness routine and send your best attempt to hello@getmulu.com to get your points!",
                            "Video workout": "- Complete this 10 minute P90X inspired workout!",
                            "Alternating jump lunges": "- Do 60 alternating jump lunges (each side counts as 1)\n- Pay special attention to form to avoid injury! Keep core tight, drop into a low lunge when you land, and bend both knees to 90 degrees.",
                            "Tricep dip hold": "- Use a chair or bench and do a tricep hold for a total of 2 minutes. Break it up or do in one run!\n- Lower yourself until your elbows are bent between 45-90 degrees\n- Keep your shoulders relaxed/down and only dip as low as you're comfortable with",
                            "JB workout!": "- Learn this short fitness routine and send your best attempt to hello@getmulu.com to get your points!",
                            "Crunches": "- Have your movement be driven by your core, not your head/neck\n- Keep your head and neck relaxed to avoid injury\n- Works your abs, obliques, pelvis, and hips",
                            "Plank waks": "- Complete 3 minutes of plank walks (45 second plank walk, 15 second break)\n- Keep your core tight and your body in a straight line throughout\n- Works your core, shoulders, chest, and arms",
                            "Russian twists": "- Do 48 Russian Twist reps where going left then right counts as 1\n- Keep your core tight throughout\n- Works your core, obliques, and spine",
                            "Hot and Dangerous 🔥": "- Learn this short fitness routine and send your best attempt to hello@getmulu.com to get your points!"]
    
    //==================================================//
    
    /* Public Functions */
    
    /**
     Creates a specified number of random **Challenges** on the server.
     
     - Parameter amountToCreate: The amount of **Challenges** to create. *Defaults to 1.*
     - Parameter completion: Upon success, returns with an array **Challenge** objects. Upon failure, a string describing the error(s) encountered.
     
     - Note: Completion variables are **NOT** *mutually exclusive.*
     - Requires: `amountToCreate` to be more than 0, and less than or equal to the count of `sampleChallenges`.
     
     ~~~
     completion(returnedChallenges, errorDescriptor)
     ~~~
     */
    func createRandomChallenges(amountToCreate: Int?, completion: @escaping(_ returnedChallenges: [Challenge]?, _ errorDescriptor: String?) -> Void)
    {
        let amount = amountToCreate ?? 1
        
        guard amount != 0 else
        { completion(nil, "Can't create 0 random Challenges."); return }
        
        guard amount <= sampleChallenges.count else
        { completion(nil, "Requested more than amount of challenge data."); return }
        
        let group = DispatchGroup()
        
        var challenges: [Challenge] = []
        var errors: [String] = []
        
        for _ in 0..<amount
        {
            group.enter()
            
            createRandomChallenge(excludingTitles: challenges.titles()) { (returnedChallenge, errorDescriptor) in
                if let error = errorDescriptor
                {
                    errors.append(error)
                    group.leave()
                }
                else if let challenge = returnedChallenge
                {
                    challenges.append(challenge)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(challenges, errors.count > 0 ? errors.joined(separator: "\n") : nil)
        }
    }
    
    /**
     Generates an random array of completed **Challenges** from an array of provided **Challenges.**
     
     - Parameter fromChallenges: The **Challenge** objects from which to create the array.
     - Parameter withUsers: The **Users** objects from which to generate random metadata.
     
     - Returns: An array of completed **Challenges.**
     */
    func randomCompletedChallenges(fromChallenges challenges: [Challenge], withUsers users: [User]) -> [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]
    {
        var completedChallenges: [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])] = []
        
        for challenge in challenges
        {
            var metadata: [(user: User, dateCompleted: Date)] = []
            
            var metadataFillNumber = Int().random(min: 1, max: 3)
            
            while metadataFillNumber > 0
            {
                let randomUser = users.randomElement()!
                
                let todayStartTime = Date().comparator
                let datePostedStartTime = challenge.datePosted.comparator
                
                let differenceBetweenDates = todayStartTime.distance(to: datePostedStartTime)
                
                if differenceBetweenDates < 0
                {
                    let randomTimeOfCompletion = Int().random(min: Int(datePostedStartTime.timeIntervalSince1970), max: Int(todayStartTime.timeIntervalSince1970))
                    
                    metadata.append((randomUser, Date(timeIntervalSince1970: TimeInterval(randomTimeOfCompletion))))
                }
                
                metadataFillNumber -= 1
            }
            
            let cleanedMetadata = self.cleanMetadata(metadata)
            completedChallenges.append((challenge, cleanedMetadata))
        }
        
        return completedChallenges
    }
    
    //==================================================//
    
    /* Private Functions */
    
    /**
     Returns an array of unique metadata from an array of provided completed **Challenge** metadata.
     
     - Parameter metadata: The metadata tuples to clean.
     
     - Returns: An array of `(User, Date)` tuples.
     */
    private func cleanMetadata(_ metadata: [(user: User, dateCompleted: Date)]) -> [(user: User, dateCompleted: Date)]
    {
        var cleanedMetadata: [(user: User, dateCompleted: Date)] = []
        
        for datum in metadata
        {
            if !cleanedMetadata.contains(where: {$0.user.associatedIdentifier == datum.user.associatedIdentifier})
            {
                cleanedMetadata.append((datum.user, datum.dateCompleted))
            }
        }
        
        return cleanedMetadata
    }
    
    /**
     Creates a random **Challenge** on the server.
     
     - Parameter excludingTitles: An optional array providing title strings to exclude when generating a random title.
     - Parameter completion: Upon success, returns with a **Challenge** object. Upon failure, a string describing the error encountered.
     
     - Note: Completion variables are *mutually exclusive.*
     
     ~~~
     completion(returnedChallenge, errorDescriptor)
     ~~~
     */
    private func createRandomChallenge(excludingTitles: [String]?, completion: @escaping(_ returnedChallenge: Challenge?, _ errorDescriptor: String?) -> Void)
    {
        let randomDate = masterDateFormatter.date(from: "2020-12-\(Int().random(min: 1, max: Calendar.current.component(.day, from: Date())))")!
        
        let randomChallengeTitle = excludingTitles == nil ? Array(sampleChallenges.keys).randomElement()! : Array(sampleChallenges.keys).filter({!excludingTitles!.contains($0)}).randomElement()!
        let randomChallengePrompt = sampleChallenges[randomChallengeTitle]!
        
        ChallengeSerialiser().createChallenge(title: randomChallengeTitle,
                                              prompt: randomChallengePrompt,
                                              datePosted: randomDate,
                                              pointValue: Int().random(min: 10, max: 500),
                                              media: nil) { (returnedIdentifier, errorDescriptor) in
            if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else if let identifier = returnedIdentifier
            {
                ChallengeSerialiser().getChallenge(withIdentifier: identifier) { (returnedChallenge, errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        completion(nil, error)
                    }
                    else if let challenge = returnedChallenge
                    {
                        completion(challenge, nil)
                        
                    }
                    else { completion(nil, "Unable to retrieve created Challenge.") }
                }
            }
            else { completion(nil, "An unknown error occurred.") }
        }
    }
}
