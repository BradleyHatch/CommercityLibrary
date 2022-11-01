
export default function returnNewReduxState(state, action) {
    return Object.assign({}, state, action);
}
