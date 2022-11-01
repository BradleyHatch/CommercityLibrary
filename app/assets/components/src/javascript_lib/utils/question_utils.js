import QUESTION_KEYS from 'constants/requested_data_keys/question_keys';


export function allowNext(currentIndex, questions) {
  return currentIndex < questions.length - 1;
}

export function allowPrevious(currentIndex) {
  return currentIndex > 0;
}

export function getSaveAnswersObject(answers) {
  const answersArray = Object.keys(answers).map(key => {
    return {[QUESTION_KEYS.ID]: answers[key][0]};
  });

  return {answers: answersArray}
}


function getFirstQuestion(originalQuestions) {
  return originalQuestions.filter(question => question[QUESTION_KEYS.ANSWER_DEPENDANCIES].length === 0);
}

function getNextQuestion(originalQuestions, questions, answer) {
  const nextQuestion = originalQuestions.filter(question => question[QUESTION_KEYS.ID] === answer[QUESTION_KEYS.QUESTION_DEPENDANCIES][0]);

  return questions.concat(nextQuestion);
}

export function getLinkedQuestions(originalQuestions, questions=null, answer=null) {
  if(answer === null) {
    return getFirstQuestion(originalQuestions);
  } else {
    return getNextQuestion(originalQuestions, questions, answer);
  }
}

function currentQuestion(questions, currentIndex) {
  return questions[currentIndex];
}

export function currentKey(questions, currentIndex) {
  return currentQuestion(questions, currentIndex)[QUESTION_KEYS.ID];
}

export function currentQuestionIsMultiChoice(questions, currentIndex) {
  return !!currentQuestion(questions, currentIndex).multi_choice;
}

function questionDependeciesHaveBeenMet(question, answers) {
  if(question[QUESTION_KEYS.ANSWER_DEPENDANCIES] == null || question[QUESTION_KEYS.ANSWER_DEPENDANCIES].length === 0) {
    return true;
  }

  return Object.keys(question[QUESTION_KEYS.ANSWER_DEPENDANCIES]).every(dependencyKey => {
    return question[QUESTION_KEYS.ANSWER_DEPENDANCIES][dependencyKey].every(dependencyValue => {
      return answers[dependencyKey] && answers[dependencyKey].includes(dependencyValue);
    });
  });
}

export function filterQuestions(questions, answers) {
  return questions.filter(question => {
    return answers[question[QUESTION_KEYS.ID]] ? true : questionDependeciesHaveBeenMet(question, answers);
  });
}

function answerContainsValue(answers, questionKey, value) {
    return answers[questionKey] && !answers[questionKey].includes(value);
  }

export function addAnswer(questions, currentIndex, answers, answer) {
  const currentID = currentKey(questions, currentIndex);
  const questionIsMultiChoiceAndCurrentKeyHasValue = currentQuestionIsMultiChoice(questions, currentIndex)
    && answerContainsValue(answers, currentID, answer[QUESTION_KEYS.ID]);
  const newAnswer = questionIsMultiChoiceAndCurrentKeyHasValue
    ? {[currentID]: answers[currentID].concat(answer[QUESTION_KEYS.ID])}
    : {[currentID]: [answer[QUESTION_KEYS.ID]]};

  return Object.assign({}, answers, newAnswer);
}

export function answerHasALinkedQuestion(answer) {
  return answer[QUESTION_KEYS.QUESTION_DEPENDANCIES] && answer[QUESTION_KEYS.QUESTION_DEPENDANCIES].length > 0;
}

export function getViewAnswersArray(questions, answers) {
  const answersKeys = Object.keys(answers);
  return answersKeys.map(questionId => {
    const question = findQuestionOrAnswer(questions, questionId)[0];

    return findQuestionOrAnswer(question[QUESTION_KEYS.ANSWERS], answers[questionId][0]);
  });
}

function findQuestionOrAnswer(questionsOrAnswers, id) {
  return questionsOrAnswers.filter(question => question[QUESTION_KEYS.ID] == id);
}

export function getPreviousQuestionsIndex(questions, answer, currentIndex=0) {
  const foundIndex = questions.findIndex(question => {
    return question[QUESTION_KEYS.ID] === answer[0][QUESTION_KEYS.QUESTION_ID];
  });

  return foundIndex != null ? foundIndex : currentIndex;
}

export function answeringPreviousQuestion(answers, answer) {
  return answers[answer[QUESTION_KEYS.QUESTION_ID]] != null;
}

export function createAnswersObjectFromPrevious(questions, answers, questionIdToAdd=null, answerIdToAdd=null) {
  let newAnswers = questions.reduce((newAnswersObject, question) => {
    newAnswersObject[question[QUESTION_KEYS.ID]] = answers[question[QUESTION_KEYS.ID]];

    return newAnswersObject;
  }, {});

  if(questionIdToAdd) {
    newAnswers[questionIdToAdd] = [answerIdToAdd];
  }

  return newAnswers;
}

export function answerPreviousQuestion(originalQuestions, questions, currentIndex, answers, answer) {
  const previousAnswerId = answers[answer[QUESTION_KEYS.QUESTION_ID]][0];
  const answerId = answer[QUESTION_KEYS.ID];
  const sameAnswerWasGiven = previousAnswerId === answerId;
  const questionAnswered = findQuestionOrAnswer(originalQuestions, answer[QUESTION_KEYS.QUESTION_ID])[0];
  const previousAnswer = findQuestionOrAnswer(questionAnswered[QUESTION_KEYS.ANSWERS], previousAnswerId)[0];
  const newAnswerLeadsToTheSameQuestion = previousAnswer[QUESTION_KEYS.QUESTION_DEPENDANCIES][0] === answer[QUESTION_KEYS.QUESTION_DEPENDANCIES][0];

  if(sameAnswerWasGiven) {
    return {
      questions,
      answers
    };
  } else if(newAnswerLeadsToTheSameQuestion) {
    return {
      questions,
      answers: createAnswersObjectFromPrevious(questions.slice(0, questions.length - 1), answers, questionAnswered[QUESTION_KEYS.ID], answerId)
    }
  } else {
    const indexOfQuestion = getPreviousQuestionsIndex(questions, [answer]);
    const questionsBeforeChangeIncludingCurrent = questions.slice(0, indexOfQuestion + 1);
    const questionsBeforeChange = questions.slice(0, indexOfQuestion);
    const newQuestions = getNextQuestion(originalQuestions, questionsBeforeChangeIncludingCurrent, answer);
    let newAnswers = createAnswersObjectFromPrevious(questionsBeforeChange, answers, questionAnswered[QUESTION_KEYS.ID], answerId);

    return {
      questions: newQuestions,
      answers: newAnswers
    };
  }
}
